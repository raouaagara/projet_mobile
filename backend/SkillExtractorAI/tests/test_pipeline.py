"""Unit tests of the text utilities and of the lexicon (exact) stage — no model needed."""
from app.extractor import CatalogItem, SkillExtractor
from app.lexicon import load_lexicon
from app.text_utils import detect_language, extract_candidates, find_sections, normalize

EXTRACTOR = SkillExtractor(load_lexicon(), model=None)


def names(text: str, catalog=None) -> set[str]:
    return {h.name for h in EXTRACTOR.extract_text(text, catalog, semantic=False).skills}


def test_normalize_keeps_length_and_removes_accents():
    text = "Compétences Clés — Développement"
    norm = normalize(text)
    assert len(norm) == len(text)
    assert norm == "competences cles - developpement"


def test_detect_language():
    assert detect_language("J'ai travaillé dans une entreprise pour le développement des applications")[0] == "fr"
    assert detect_language("I worked for a company on the development of the applications and the team")[0] == "en"
    assert detect_language("Java Flutter")[0] == "unknown"


def test_find_sections():
    norm = normalize("PROFIL\nBla\nCOMPÉTENCES TECHNIQUES\nJava\nEXPÉRIENCE\nStage chez Vermeg (2023)")
    assert [s.name for s in find_sections(norm)] == ["other", "skills", "experience"]


def test_candidates_skip_contact_details():
    cands = {c.norm for c in extract_candidates(normalize("john@mail.com | +216 22 333 444\nGestion de projet, Scrum"))}
    assert "gestion de projet" in cands and "scrum" in cands
    assert not any("@" in c for c in cands)


def test_word_boundaries_java_vs_javascript():
    found = names("SKILLS\nJavaScript, TypeScript")
    assert "JavaScript" in found and "Java" not in found


def test_longest_match_wins():
    found = names("SKILLS\nReact Native, Spring Boot")
    assert {"React Native", "Spring Boot"} <= found
    assert "React" not in found and "Spring Framework" not in found


def test_ambiguous_words_only_in_skills_section():
    prose = "PROFIL\nJe présente un tableau de bord. In spring 2023 I had to go fast and react quickly."
    assert not {"Tableau", "Spring Framework", "Go", "React"} & names(prose)
    assert {"Tableau", "Go", "C"} <= names("COMPÉTENCES\nTableau, Go, C")


def test_french_aliases():
    found = names("COMPÉTENCES\nGestion de projet, apprentissage automatique, tests unitaires, bases de données")
    assert {"Project Management", "Machine Learning", "Unit Testing", "Databases"} <= found


def test_catalog_items_are_linked_to_the_lexicon():
    catalog = [CatalogItem(7, "Gestion de Projet"), CatalogItem(8, "NodeJS"), CatalogItem(9, "Rust")]
    result = EXTRACTOR.extract_text("SKILLS\nProject management, Node.js, Docker", catalog, semantic=False)
    assert {(h.id, h.name) for h in result.skills} == {(7, "Gestion de Projet"), (8, "NodeJS")}
    assert "Docker" in result.other_skills  # found in the CV but not in the catalog


def test_confidence_is_higher_in_skills_section():
    result = EXTRACTOR.extract_text("EXPERIENCE\nUsed Docker.\nSKILLS\nFlutter", semantic=False)
    by_name = {h.name: h for h in result.skills}
    assert by_name["Flutter"].in_skills_section and not by_name["Docker"].in_skills_section
    assert by_name["Flutter"].confidence > by_name["Docker"].confidence


def test_empty_text_warns():
    assert EXTRACTOR.extract_text("   ", semantic=False).warnings
