"""Skill extraction pipeline.

1. Exact / alias matching (bilingual lexicon, word boundaries, longest match wins).
2. Section awareness: ambiguous words only count in the Skills section; skills found
   there get a confidence boost.
3. Semantic matching with a multilingual embedding model for everything the
   lexicon missed (paraphrases, French ↔ English).
"""
from __future__ import annotations

import re
import time
from dataclasses import dataclass, field

import numpy as np

from .lexicon import LexiconSkill, alias_variants
from .semantic import SemanticModel
from .text_utils import Section, detect_language, extract_candidates, find_sections, normalize, section_at

# Similarity thresholds, calibrated on eval/ (see eval/evaluate.py).
SEMANTIC_THRESHOLD = 0.80
SEMANTIC_THRESHOLD_SINGLE_WORD = 0.90


@dataclass
class CatalogItem:
    id: int | None
    name: str


@dataclass
class SkillHit:
    id: int | None
    name: str
    confidence: float
    method: str  # exact | alias | semantic
    evidence: str
    in_skills_section: bool
    mentions: int


@dataclass
class ExtractionResult:
    language: str
    language_confidence: float
    text_length: int
    skills_section_found: bool
    semantic_enabled: bool
    skills: list[SkillHit]
    other_skills: list[str]  # lexicon skills found in the CV but absent from the catalog
    warnings: list[str] = field(default_factory=list)
    elapsed_ms: int = 0


@dataclass
class _Target:
    id: int | None
    name: str
    patterns: list[tuple[str, re.Pattern, bool]]  # (normalized alias, regex, section only)
    semantic_texts: list[str]


def _compile(alias: str) -> re.Pattern:
    body = r"\s+".join(re.escape(w) for w in alias.split())
    return re.compile(r"(?<![a-z0-9+#])" + body + r"(?![a-z0-9+#])")


class SkillExtractor:
    def __init__(self, lexicon: list[LexiconSkill], model: SemanticModel | None = None) -> None:
        self.lexicon = lexicon
        self.model = model
        self._index: dict[str, LexiconSkill] = {}
        for skill in lexicon:
            for key in {normalize(skill.name), *skill.norm_aliases}:
                for variant in alias_variants(key):
                    self._index.setdefault(variant, skill)
        self._lexicon_targets = [self._target(None, s.name) for s in lexicon]

    # ── targets ──

    def lookup(self, name: str) -> LexiconSkill | None:
        """The lexicon entry of a skill name or alias ("NodeJS" → Node.js), or None."""
        for variant in alias_variants(name):
            if variant in self._index:
                return self._index[variant]
        return None

    def _target(self, id_: int | None, name: str) -> _Target:
        entry = self.lookup(name)
        aliases: set[str] = set(alias_variants(name))
        section_only: set[str] = set()
        norm_name = normalize(name).strip()
        # Only concepts are matched by meaning, against English prototypes (the model
        # aligns FR and EN; French prototypes would favour any French phrase).
        semantic_texts: list[str] = []
        if entry:
            for a in entry.norm_aliases:
                aliases |= alias_variants(a)
            section_only = set(entry.section_only)
            if entry.concept:
                semantic_texts = [entry.name, *entry.examples]
        elif len(norm_name.split()) >= 2 and not re.search(r"[\d.#+]", norm_name):
            semantic_texts = [name]  # unknown multi-word catalog skill: treat as a concept
        if len(norm_name) <= 2 and entry is None:
            section_only.add(norm_name)  # unknown 1–2 letter skill: too ambiguous elsewhere
        patterns = [(a, _compile(a), a in section_only) for a in sorted(aliases) if a]
        return _Target(id_, name, patterns, list(dict.fromkeys(semantic_texts)))

    # ── pipeline ──

    def extract_text(self, text: str, catalog: list[CatalogItem] | None = None, semantic: bool = True) -> ExtractionResult:
        started = time.perf_counter()
        warnings: list[str] = []
        norm = normalize(text)
        language, lang_conf = detect_language(text)
        sections = find_sections(norm)
        has_skills_section = any(s.name == "skills" for s in sections)

        if len(text.strip()) < 50:
            warnings.append("Almost no text found: the PDF may be a scanned image (OCR is not supported).")

        targets = [self._target(c.id, c.name) for c in catalog] if catalog else self._lexicon_targets
        hits, taken = self._exact(norm, text, sections, targets)

        semantic_on = bool(semantic and self.model and self.model.ready)
        if semantic and not semantic_on:
            warnings.append("Semantic model not loaded yet: exact matching only.")
        if semantic_on:
            hits.update(self._semantic(norm, text, sections, targets, hits, taken))

        other: list[str] = []
        if catalog:
            found_names = {normalize(h.name) for h in hits.values()}
            lex_hits, _ = self._exact(norm, text, sections, self._lexicon_targets)
            other = sorted({h.name for h in lex_hits.values() if normalize(h.name) not in found_names
                            and not any(self.lookup(h.name) is self.lookup(n) for n in found_names)})

        skills = sorted(hits.values(), key=lambda h: (-h.confidence, h.name))
        return ExtractionResult(
            language=language,
            language_confidence=round(lang_conf, 2),
            text_length=len(text),
            skills_section_found=has_skills_section,
            semantic_enabled=semantic_on,
            skills=skills,
            other_skills=other,
            warnings=warnings,
            elapsed_ms=int((time.perf_counter() - started) * 1000),
        )

    def _exact(self, norm: str, original: str, sections: list[Section], targets: list[_Target]):
        flat = norm.replace("\n", " ")
        found = []
        for ti, target in enumerate(targets):
            for alias, rx, section_only in target.patterns:
                for m in rx.finditer(flat):
                    found.append((m.start(), m.end(), ti, alias, section_only))
        found.sort(key=lambda f: (-(f[1] - f[0]), f[0]))

        taken: list[tuple[int, int]] = []
        hits: dict[int, SkillHit] = {}
        for start, end, ti, alias, section_only in found:
            if any(start < te and ts < end for ts, te in taken):
                continue  # inside a longer match ("react" inside "react native")
            in_skills = section_at(sections, start) == "skills"
            if section_only and not in_skills:
                continue
            taken.append((start, end))
            target = targets[ti]
            hit = hits.get(ti)
            if hit is None:
                exact = alias in alias_variants(target.name)
                hits[ti] = SkillHit(target.id, target.name, 0.0, "exact" if exact else "alias",
                                    original[start:end], in_skills, 1)
            else:
                hit.mentions += 1
                hit.in_skills_section |= in_skills
        for hit in hits.values():
            base = 0.90 if hit.method == "exact" else 0.85
            hit.confidence = round(min(0.99, base + (0.05 if hit.in_skills_section else 0)
                                       + 0.03 * min(hit.mentions - 1, 2)), 2)
        return hits, taken

    def _semantic(self, norm, original, sections, targets, hits, taken):
        concepts = [i for i, t in enumerate(targets) if t.semantic_texts]
        if not any(i not in hits for i in concepts):
            return {}
        candidates = [
            c for c in extract_candidates(norm)
            if sum(max(0, min(c.end, te) - max(c.start, ts)) for ts, te in taken) < 0.5 * (c.end - c.start)
        ]
        if not candidates:
            return {}

        # Prototype classifier: similarity(candidate, skill) = best cosine between the
        # candidate phrase and the skill's prototypes (English name + examples).
        cand_texts = [re.sub(r"\s+", " ", original[c.start:c.end]) for c in candidates]
        proto_texts, owners = [], []
        for i in concepts:
            for t in targets[i].semantic_texts:
                proto_texts.append(t)
                owners.append(concepts.index(i))
        proto_sims = self.model.embed(proto_texts) @ self.model.embed(cand_texts).T
        sims = np.full((len(concepts), len(candidates)), -1.0, dtype=np.float32)
        for row, k in enumerate(owners):
            np.maximum(sims[k], proto_sims[row], out=sims[k])

        # Each phrase votes for its single closest concept (skills already found by the
        # lexicon compete too, so "machine learning models" can't also give Deep Learning).
        best_concept = np.argmax(sims, axis=0)
        single_word = np.array([len(c.norm.split()) == 1 for c in candidates])
        thresholds = np.where(single_word, SEMANTIC_THRESHOLD_SINGLE_WORD, SEMANTIC_THRESHOLD)

        out: dict[int, SkillHit] = {}
        best_sim: dict[int, float] = {}
        for j, k in enumerate(best_concept):
            ti = concepts[int(k)]
            sim = float(sims[k, j])
            if ti in hits or sim < thresholds[j] or sim <= best_sim.get(ti, -1.0):
                continue
            best_sim[ti] = sim
            thr = float(thresholds[j])
            in_skills = section_at(sections, candidates[j].start) == "skills"
            conf = 0.60 + (sim - thr) / (1 - thr) * 0.30 + (0.05 if in_skills else 0)
            out[ti] = SkillHit(targets[ti].id, targets[ti].name, round(min(conf, 0.95), 2), "semantic",
                               cand_texts[j], in_skills, 1)
        return out
