"""Text helpers: normalization, language detection, CV sections, candidate phrases.

`normalize()` keeps the text length unchanged, so an offset in the normalized
text is also valid in the original text (used to quote evidence and to feed the
original wording to the embedding model).
"""
from __future__ import annotations

import re
import unicodedata
from dataclasses import dataclass

_LIGATURES = {"ﬁ": "fi", "ﬂ": "fl", "ﬀ": "ff", "ﬃ": "ffi", "ﬄ": "ffl", "ﬅ": "st", "ﬆ": "st"}
_PUNCT = {"’": "'", "‘": "'", "´": "'", "`": "'", "–": "-", "—": "-", "‐": "-", "‑": "-", " ": " ", "\t": " "}


def clean_pdf_text(text: str) -> str:
    """Fixes PDF artefacts (ligatures, soft hyphens) that change the text length."""
    for lig, repl in _LIGATURES.items():
        text = text.replace(lig, repl)
    text = text.replace("­", "")  # soft hyphen
    text = re.sub(r"\r\n?", "\n", text)
    return text


def _fold_char(ch: str) -> str:
    if ch in _PUNCT:
        return _PUNCT[ch]
    base = "".join(c for c in unicodedata.normalize("NFKD", ch) if not unicodedata.combining(c))
    low = base.lower() if len(base) == 1 else ch.lower()
    return low if len(low) == 1 else ch


def normalize(text: str) -> str:
    """Lowercase, remove accents, unify quotes/dashes — same length as `text`."""
    return "".join(_fold_char(ch) for ch in text)


# ── Language detection (stop-word ratio: robust for FR vs EN, no model needed) ──

_FR_STOPWORDS = set(
    "le la les un une des du de et en au aux pour par sur dans avec sans sous chez est sont "
    "été être avoir ai ont nous vous ils elles je il elle ce cette ces mon ma mes son sa ses "
    "leur leurs qui que quoi dont où ou mais donc car ne pas plus très aussi comme entre "
    "depuis lors ainsi afin ans mois stage expérience formation compétences langues".split()
)
_EN_STOPWORDS = set(
    "the a an and or of to in on for with by at from as is are was were be been have has had "
    "i we you he she they it this that these those my our your his her their which who what "
    "not but so than very also into over under about during years months internship "
    "experience education skills languages".split()
)


def detect_language(text: str) -> tuple[str, float]:
    words = re.findall(r"[a-zà-ÿ']+", text.lower())
    fr = sum(w in _FR_STOPWORDS for w in words)
    en = sum(w in _EN_STOPWORDS for w in words)
    total = fr + en
    if total < 5:
        return "unknown", 0.0
    return ("fr", fr / total) if fr >= en else ("en", en / total)


# ── CV sections ──

_HEADINGS = {
    "skills": [
        "competences", "competences techniques", "competences cles", "competences informatiques",
        "skills", "technical skills", "hard skills", "soft skills", "key skills", "it skills",
        "core competencies", "competencies", "savoir-faire", "savoir faire", "savoir-etre",
        "outils", "tools", "technologies", "stack technique", "stack", "environnement technique",
        "langages", "langages de programmation", "programming languages", "logiciels", "software",
        "expertise", "expertises", "qualifications", "aptitudes", "connaissances",
        "connaissances techniques", "informatique", "tech stack", "frameworks",
    ],
    "experience": [
        "experience", "experiences", "experience professionnelle", "experiences professionnelles",
        "professional experience", "work experience", "employment", "employment history",
        "parcours professionnel", "stages", "stage", "internships", "internship",
    ],
    "education": [
        "education", "formation", "formations", "diplomes", "diplome", "academic background",
        "parcours academique", "cursus", "etudes",
    ],
    "projects": ["projets", "projects", "projets academiques", "academic projects", "realisations", "projets personnels", "personal projects"],
    "languages": ["langues", "languages", "langues etrangeres", "language skills"],
    "other": [
        "certifications", "certificats", "certificates", "loisirs", "interests", "hobbies",
        "centres d'interet", "centres d interet", "references", "profil", "profile", "summary",
        "resume", "a propos", "about", "about me", "contact", "objectif", "objective",
        "activites", "vie associative", "benevolat", "volunteering", "awards", "prix",
    ],
}
_HEADING_LOOKUP = {h: name for name, heads in _HEADINGS.items() for h in heads}


@dataclass(frozen=True)
class Section:
    name: str
    start: int
    end: int


def _heading_of(line: str) -> str | None:
    clean = re.sub(r"[^a-z' -]", " ", line).strip(" -")
    clean = re.sub(r"\s+", " ", clean)
    if not clean or len(clean) > 45 or len(clean.split()) > 5:
        return None
    if clean in _HEADING_LOOKUP:
        return _HEADING_LOOKUP[clean]
    for head, name in _HEADING_LOOKUP.items():
        # "competences techniques & outils", "skills and tools"
        if name == "skills" and clean.startswith(head + " ") and len(clean) <= len(head) + 25:
            return name
    return None


def find_sections(norm_text: str) -> list[Section]:
    """Splits the normalized text into sections, based on heading lines."""
    heads: list[tuple[int, str]] = []
    offset = 0
    for line in norm_text.split("\n"):
        name = _heading_of(line)
        if name:
            heads.append((offset, name))
        offset += len(line) + 1
    sections = []
    for i, (start, name) in enumerate(heads):
        end = heads[i + 1][0] if i + 1 < len(heads) else len(norm_text)
        sections.append(Section(name, start, end))
    return sections


def section_at(sections: list[Section], offset: int) -> str | None:
    for s in sections:
        if s.start <= offset < s.end:
            return s.name
    return None


# ── Candidate phrases for the semantic model ──

_SEPARATORS = re.compile(r"[\n•●▪◦■►➢➤✓✔★;|,()\[\]{}:]+|\s[-/+&]\s|\.(?=\s)|\s{3,}")
_JUNK = re.compile(r"@|https?://|www\.|\d{2}[/.-]\d{2}|^\d+$|\+?\d[\d ]{7,}")
_MAX_WORDS = 6


@dataclass(frozen=True)
class Candidate:
    start: int
    end: int
    norm: str


def extract_candidates(norm_text: str, limit: int = 1500) -> list[Candidate]:
    """Short phrases (1–6 words) of the CV: bullet items, list items, n-grams of long lines."""
    out: dict[str, Candidate] = {}

    def add(start: int, end: int) -> None:
        phrase = norm_text[start:end]
        stripped = phrase.strip(" -.'\"")
        if len(stripped) < 2 or not re.search(r"[a-z]", stripped) or _JUNK.search(stripped):
            return
        start += len(phrase) - len(phrase.lstrip(" -.'\""))
        norm = re.sub(r"\s+", " ", stripped)
        if norm not in out:
            out[norm] = Candidate(start, start + len(stripped), norm)

    pos = 0
    for sep in [*_SEPARATORS.finditer(norm_text), None]:
        seg_end = sep.start() if sep else len(norm_text)
        segment = norm_text[pos:seg_end]
        words = list(re.finditer(r"\S+", segment))
        if 1 <= len(words) <= _MAX_WORDS:
            add(pos + words[0].start(), pos + words[-1].end())
        elif len(words) > _MAX_WORDS:
            if len(words) <= 15:  # whole bullet sentence: paraphrases need the full context
                add(pos + words[0].start(), pos + words[-1].end())
            for n in (2, 3, 4):
                for i in range(len(words) - n + 1):
                    add(pos + words[i].start(), pos + words[i + n - 1].end())
        if sep:
            pos = sep.end()
        if len(out) >= limit:
            break
    return list(out.values())
