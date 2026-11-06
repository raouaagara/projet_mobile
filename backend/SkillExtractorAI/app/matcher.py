"""Freelancer ↔ job match score (module 2: "Recommended for you").

A job's skills are the ones the client required plus the ones found in its title and
description (same pipeline as CVs: bilingual lexicon + multilingual model). The score is
mainly how much of that the freelancer covers:
  • the same skill, or an alias (NodeJS = Node.js)                     → full credit
  • a related skill (same field, e.g. React Native for a Flutter job)  → partial credit
Raw embedding similarity between two skill names is not reliable (with this model Flutter
is closer to Docker than to Dart), so it never decides a skill on its own. It only adds a
small bonus from how close the whole job text is to the profile, and is the only signal
for a job in which no skill is recognised.
"""
from __future__ import annotations

from collections import OrderedDict
from dataclasses import dataclass, field

import numpy as np

from .extractor import SkillExtractor
from .text_utils import normalize

RELATED_CREDIT = 0.5
# Fields too broad to make two skills "related" (two soft skills, two spoken languages...).
BROAD_CATEGORIES = {"Soft skills", "Concepts", "Languages"}
REQUIRED_WEIGHT = 1.0
# Skills found in the text count less when the client also listed the required ones.
FOUND_WEIGHT_WITH_REQUIRED = 0.4
FOUND_WEIGHT_ALONE = 1.0
BROAD_WEIGHT = 0.3
# A guess by meaning below this confidence only counts when the freelancer has the skill.
SURE_SEMANTIC = 0.7
TEXT_BONUS = 0.15
# Cosine between a profile and a job text, measured on the model: ~0.05 unrelated, ~0.35 very close.
TEXT_SIM_LOW, TEXT_SIM_HIGH = 0.05, 0.35
NO_SKILL_CAP = 0.5  # a job without recognised skills is judged on meaning only: at most 50
MAX_JOB_TEXT = 1500
CACHE_SIZE = 500


@dataclass
class Job:
    id: int
    text: str
    required: list[str] = field(default_factory=list)


@dataclass
class MatchResult:
    id: int
    score: int  # 0–100
    matched: list[str]  # job skills the freelancer has
    related: list[str]  # job skills the freelancer has something close to
    missing: list[str]  # job skills the freelancer doesn't have


@dataclass
class _Skill:
    key: str  # canonical, for comparisons
    name: str  # shown to the user
    category: str


class Matcher:
    def __init__(self, extractor: SkillExtractor) -> None:
        self.extractor = extractor
        self._found: OrderedDict[tuple[str, bool], list[tuple[str, float, str]]] = OrderedDict()

    @property
    def _semantic_ready(self) -> bool:
        return bool(self.extractor.model and self.extractor.model.ready)

    def _skill(self, name: str) -> _Skill:
        entry = self.extractor.lookup(name)
        if entry:
            return _Skill(entry.name.lower(), entry.name, entry.category)
        return _Skill(normalize(name).strip(), name.strip(), "")

    def _found_in_text(self, text: str) -> list[tuple[str, float, str]]:
        """Skills found in a job text as (name, confidence, method). Cached: jobs rarely change."""
        key = (text, self._semantic_ready)
        if key in self._found:
            self._found.move_to_end(key)
            return self._found[key]
        found = [(h.name, h.confidence, h.method) for h in self.extractor.extract_text(text).skills]
        self._found[key] = found
        if len(self._found) > CACHE_SIZE:
            self._found.popitem(last=False)
        return found

    def _text_scores(self, mine: list[_Skill], jobs: list[Job]) -> list[float] | None:
        """How close each job text is to the profile, 0–1. None when the model isn't loaded."""
        if not self._semantic_ready or not mine or not jobs:
            return None
        profile = "Skills: " + ", ".join(s.name for s in mine)
        vectors = self.extractor.model.embed([profile, *(j.text[:MAX_JOB_TEXT] or "-" for j in jobs)])
        sims = vectors[1:] @ vectors[0]
        return [float(x) for x in np.clip((sims - TEXT_SIM_LOW) / (TEXT_SIM_HIGH - TEXT_SIM_LOW), 0, 1)]

    def match(self, profile: list[str], jobs: list[Job]) -> list[MatchResult]:
        mine = {s.key: s for s in map(self._skill, profile) if s.key}
        my_fields = {s.category for s in mine.values() if s.category and s.category not in BROAD_CATEGORIES}
        text_scores = self._text_scores(list(mine.values()), jobs)
        return [self._score(job, mine, my_fields, text_scores[i] if text_scores else None)
                for i, job in enumerate(jobs)]

    def _score(self, job: Job, mine: dict[str, _Skill], my_fields: set[str], text_score: float | None) -> MatchResult:
        weights: dict[str, tuple[_Skill, float]] = {}

        def add(skill: _Skill, weight: float) -> None:
            if skill.key and weight > weights.get(skill.key, (skill, 0.0))[1]:
                weights[skill.key] = (skill, weight)

        for name in job.required:
            add(self._skill(name), REQUIRED_WEIGHT)
        found_weight = FOUND_WEIGHT_WITH_REQUIRED if job.required else FOUND_WEIGHT_ALONE
        for name, confidence, method in self._found_in_text(job.text[:MAX_JOB_TEXT]):
            skill = self._skill(name)
            if method == "semantic" and confidence < SURE_SEMANTIC and skill.key not in mine:
                continue  # an uncertain guess never lowers the score
            weight = BROAD_WEIGHT if skill.category in BROAD_CATEGORIES else found_weight
            add(skill, weight * confidence if method == "semantic" else weight)

        matched, related, missing = [], [], []
        got = total = 0.0
        for skill, weight in sorted(weights.values(), key=lambda sw: (-sw[1], sw[0].name)):
            total += weight
            if skill.key in mine:
                matched.append(skill.name)
                got += weight
            elif skill.category in my_fields:
                related.append(skill.name)
                got += RELATED_CREDIT * weight
            else:
                missing.append(skill.name)

        if not mine:
            score = 0.0
        elif total == 0:
            score = NO_SKILL_CAP * (text_score or 0.0)
        elif text_score is None:
            score = got / total
        else:
            score = (1 - TEXT_BONUS) * got / total + TEXT_BONUS * text_score
        return MatchResult(job.id, round(100 * score), matched, related, missing)
