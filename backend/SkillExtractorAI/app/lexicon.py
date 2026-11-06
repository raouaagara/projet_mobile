"""Bilingual skill lexicon (data/skills_lexicon.json)."""
from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path

from .text_utils import normalize

LEXICON_PATH = Path(__file__).resolve().parent.parent / "data" / "skills_lexicon.json"


@dataclass
class LexiconSkill:
    name: str
    category: str
    aliases: list[str]
    section_only: set[str] = field(default_factory=set)  # normalized ambiguous aliases
    # Concepts (Machine Learning, SEO...) can be found by meaning; tools (Java, Figma)
    # only by name. `examples` are English prototype phrases for the semantic model.
    concept: bool = False
    examples: list[str] = field(default_factory=list)

    @property
    def norm_aliases(self) -> list[str]:
        return [normalize(a) for a in self.aliases]


def load_lexicon(path: Path = LEXICON_PATH) -> list[LexiconSkill]:
    raw = json.loads(path.read_text(encoding="utf-8"))
    return [
        LexiconSkill(
            name=item["name"],
            category=item.get("category", ""),
            aliases=item.get("aliases", []),
            section_only={normalize(a) for a in item.get("sectionOnly", [])},
            concept=item.get("concept", False),
            examples=item.get("examples", []),
        )
        for item in raw["skills"]
    ]


def alias_variants(alias: str) -> set[str]:
    """'front-end' → {'front-end', 'front end', 'frontend'}; 'node.js' → {'node.js', 'nodejs'}."""
    a = normalize(alias).strip()
    variants = {a}
    if "-" in a:
        variants |= {a.replace("-", " "), a.replace("-", "")}
    if "." in a and not a.startswith("."):
        variants.add(a.replace(".", ""))
    return {v for v in variants if v}
