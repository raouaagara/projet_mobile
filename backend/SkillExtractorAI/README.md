# Skill Extractor AI

Python service that reads a CV (PDF, **French or English**) and returns the skills it contains,
matched to the CatchOPP skill catalog, each with a confidence score and the text of the CV that
proves it.

`MS_CompetenceAndReview` calls it from `POST /Competance/ParseCV` (used by the web app and the
mobile app). If this service is down, the Java side falls back to a keyword search.

## How it works

```
PDF ──PyMuPDF──► text ──► language (FR/EN) + sections (Compétences, Expérience…)
                             │
          ┌──────────────────┴──────────────────┐
  1. Bilingual lexicon (144 skills)     2. AI model (concept skills only)
     exact names + FR/EN aliases           multilingual sentence embeddings
     "tests unitaires" → Unit Testing      "modèles prédictifs" → Machine Learning
     word boundaries: Java ≠ JavaScript    "apps for smartphones" → Mobile Development
     longest match: React Native ≠ React   each CV phrase votes for its closest skill
     ambiguous words (tableau, spring,
     go, C, R) only in the Skills section
          └──────────────────┬──────────────────┘
                 confidence (+ boost in Skills section, repeated mentions)
```

- **Model:** `sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2` (50+ languages, 384-d
  embeddings), run locally with ONNX Runtime through `fastembed`. No API key, no GPU, ~240MB,
  downloaded automatically into `models/` on first start.
- **Why a lexicon + a model:** tools (Java, Figma, Docker) are either written or not, so exact
  matching is the most precise. Concepts (Machine Learning, SEO, Project Management) are often
  paraphrased or written in French: that's where the model helps. Concept skills have a few
  English *prototype* phrases (`examples` in `data/skills_lexicon.json`); the model compares each
  CV phrase to them (nearest-prototype classification). English prototypes avoid favouring any
  French phrase just because it's French: the model aligns meaning across languages.

## Results (`eval/RESULTS.md`)

| System | Precision | Recall | F1 |
|---|---|---|---|
| Previous Java logic (`text.contains(skill)`) | 78% | 64% | 70% |
| Lexicon only | 100% | 94% | 97% |
| **Lexicon + AI model** | **98%** | **98%** | **98%** |

On French CVs the old logic only found 49% of the skills. 12 CVs (6 FR, 6 EN) with traps:
JavaScript without Java, "tableau de bord", "spring 2023", paraphrased skills. The set is small and
was also used to choose the threshold: add real, anonymized CVs to `eval/dataset.py` for a fair
test.

## Run locally

```bash
cd backend/SkillExtractorAI
python -m venv .venv
.venv/Scripts/pip install -r requirements-dev.txt        # Windows (Linux/macOS: .venv/bin/pip)
.venv/Scripts/python -m uvicorn app.main:app --port 8093
```
Swagger UI: http://localhost:8093/docs — upload a PDF and try it.

```bash
.venv/Scripts/python -m pytest              # 17 tests
.venv/Scripts/python -m eval.evaluate       # precision / recall report
.venv/Scripts/python -m eval.evaluate --sweep  # tune the semantic threshold
```

## API

`POST /extract` (multipart): `file` = PDF, `catalog` = JSON `[{"id": 1, "name": "Flutter"}, …]`
(optional — without it, skills come from the lexicon).

```json
{
  "language": "fr", "languageConfidence": 0.86, "skillsSectionFound": true, "semanticEnabled": true,
  "skills": [
    {"id": 21, "name": "Flutter", "confidence": 0.98, "method": "exact",
     "evidence": "Flutter", "inSkillsSection": true, "mentions": 2},
    {"id": 36, "name": "Machine Learning", "confidence": 0.74, "method": "semantic",
     "evidence": "Entraînement de modèles prédictifs", "inSkillsSection": false, "mentions": 1}
  ],
  "otherSkills": ["Firebase"],
  "warnings": []
}
```
`otherSkills` = skills recognised in the CV that are not in the catalog (ideas for the admin).
`POST /extract/text` does the same from raw text (JSON `{text, catalog}`). `GET /health`.

## Improve it

- Add a skill or a French/English wording: edit `data/skills_lexicon.json` (no code change).
- Scanned CVs (images) have no text layer: OCR is not supported yet.
