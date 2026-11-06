"""CatchOPP Skill Extractor AI — FastAPI service (CV skills + freelancer/job match score).

Run:   .venv/Scripts/python -m uvicorn app.main:app --port 8093
Docs:  http://localhost:8093/docs
"""
from __future__ import annotations

import json
import logging
import threading
from contextlib import asynccontextmanager

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from pydantic import BaseModel, ConfigDict, Field
from pydantic.alias_generators import to_camel

from .extractor import CatalogItem, ExtractionResult, SkillExtractor
from .lexicon import load_lexicon
from .matcher import Job, Matcher
from .pdf_text import PdfError, pdf_to_text
from .semantic import SemanticModel

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")

MAX_PDF_BYTES = 10 * 1024 * 1024

model = SemanticModel()
extractor = SkillExtractor(load_lexicon(), model)
matcher = Matcher(extractor)


@asynccontextmanager
async def lifespan(_: FastAPI):
    # Load the model in the background: the API answers right away (exact matching)
    # and switches to semantic matching as soon as the model is ready.
    threading.Thread(target=model.load, daemon=True).start()
    yield


app = FastAPI(
    title="CatchOPP Skill Extractor AI",
    version="1.0.0",
    description="Extracts skills from French or English CVs (PDF) with a bilingual lexicon "
    "and a multilingual embedding model.",
    lifespan=lifespan,
)


class _Camel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)


class CatalogItemIn(_Camel):
    id: int | None = None
    name: str


class SkillOut(_Camel):
    id: int | None
    name: str
    confidence: float
    method: str = Field(description="exact | alias | semantic")
    evidence: str = Field(description="Text of the CV that matched")
    in_skills_section: bool
    mentions: int


class ExtractionOut(_Camel):
    language: str
    language_confidence: float
    text_length: int
    skills_section_found: bool
    semantic_enabled: bool
    skills: list[SkillOut]
    other_skills: list[str]
    warnings: list[str]
    elapsed_ms: int


class TextRequest(_Camel):
    text: str
    catalog: list[CatalogItemIn] | None = None
    semantic: bool = True


class MatchJobIn(_Camel):
    id: int
    text: str = Field("", description="Title and description of the job")
    required_skills: list[str] = Field(default_factory=list, description="Names of the skills the client asked for")


class MatchRequest(_Camel):
    profile: list[str] = Field(description="Names of the freelancer's skills")
    jobs: list[MatchJobIn] = Field(max_length=1000)


class MatchOut(_Camel):
    id: int
    score: int = Field(description="0–100")
    matched: list[str] = Field(description="Job skills the freelancer has")
    related: list[str] = Field(description="Job skills the freelancer has something close to")
    missing: list[str]


def _out(result: ExtractionResult) -> ExtractionOut:
    return ExtractionOut.model_validate(result, from_attributes=True)


def _catalog(items: list[CatalogItemIn] | None) -> list[CatalogItem] | None:
    return [CatalogItem(i.id, i.name) for i in items] if items else None


@app.get("/health")
def health() -> dict:
    return {
        "status": "UP",
        "semanticModel": model.name,
        "modelLoaded": model.ready,
        "modelError": model.error,
        "lexiconSkills": len(extractor.lexicon),
    }


@app.post("/extract", response_model=ExtractionOut)
def extract_pdf(
    file: UploadFile = File(..., description="CV in PDF"),
    catalog: str | None = Form(None, description='JSON list, e.g. [{"id": 1, "name": "Flutter"}]. '
                                                "Without it, skills come from the built-in lexicon."),
    semantic: bool = Form(True),
) -> ExtractionOut:
    data = file.file.read(MAX_PDF_BYTES + 1)
    if len(data) > MAX_PDF_BYTES:
        raise HTTPException(413, "PDF larger than 10MB.")
    if not data.startswith(b"%PDF"):
        raise HTTPException(415, "Only PDF files are supported.")
    try:
        items = [CatalogItemIn.model_validate(i) for i in json.loads(catalog)] if catalog else None
    except (ValueError, TypeError) as e:
        raise HTTPException(422, f"Invalid catalog JSON: {e}") from e
    try:
        text = pdf_to_text(data)
    except PdfError as e:
        raise HTTPException(422, str(e)) from e
    return _out(extractor.extract_text(text, _catalog(items), semantic))


@app.post("/extract/text", response_model=ExtractionOut)
def extract_text(request: TextRequest) -> ExtractionOut:
    return _out(extractor.extract_text(request.text, _catalog(request.catalog), request.semantic))


@app.post("/match", response_model=list[MatchOut])
def match(request: MatchRequest) -> list[MatchOut]:
    """Scores each job for a freelancer, in the order received."""
    jobs = [Job(j.id, j.text, j.required_skills) for j in request.jobs]
    return [MatchOut.model_validate(r, from_attributes=True) for r in matcher.match(request.profile, jobs)]
