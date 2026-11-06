"""API tests with real PDFs, including the multilingual model (downloaded in models/)."""
import json

import pymupdf
import pytest
from fastapi.testclient import TestClient

from app.main import app, model


def make_pdf(text: str) -> bytes:
    doc = pymupdf.open()
    doc.new_page().insert_textbox(pymupdf.Rect(40, 40, 555, 802), text, fontsize=10, fontname="helv")
    data = doc.tobytes()
    doc.close()
    return data


@pytest.fixture(scope="module")
def client():
    with TestClient(app) as c:
        model.load()  # the app loads it in the background; tests need it now
        yield c


FR_CV = """Nour Hamdi
Développeuse Mobile

COMPÉTENCES
Flutter, Dart, Firebase

EXPÉRIENCE
• Création d'applications pour smartphones Android et iPhone.
• Entraînement de modèles prédictifs sur les données clients.
"""


def test_health(client):
    body = client.get("/health").json()
    assert body["status"] == "UP" and body["lexiconSkills"] > 100


def test_extract_french_pdf_with_catalog(client):
    catalog = [{"id": 1, "name": "Flutter"}, {"id": 2, "name": "Dart"}, {"id": 3, "name": "Machine Learning"},
               {"id": 4, "name": "Java"}, {"id": 5, "name": "Android"}]
    res = client.post("/extract", files={"file": ("cv.pdf", make_pdf(FR_CV), "application/pdf")},
                      data={"catalog": json.dumps(catalog)})
    assert res.status_code == 200
    body = res.json()
    assert body["language"] == "fr" and body["skillsSectionFound"]
    found = {s["name"]: s for s in body["skills"]}
    assert {"Flutter", "Dart", "Android", "Machine Learning"} <= set(found) and "Java" not in found
    assert found["Flutter"]["id"] == 1 and found["Flutter"]["inSkillsSection"]
    if model.ready:  # "modèles prédictifs" → Machine Learning is found by meaning
        assert found["Machine Learning"]["method"] == "semantic"
    assert "Firebase" in body["otherSkills"]


def test_extract_without_catalog_uses_lexicon(client):
    res = client.post("/extract", files={"file": ("cv.pdf", make_pdf("SKILLS\nPython, Docker, Scrum"), "application/pdf")})
    assert {"Python", "Docker", "Agile/Scrum"} <= {s["name"] for s in res.json()["skills"]}


def test_text_endpoint(client):
    res = client.post("/extract/text", json={"text": "SKILLS\nKotlin", "catalog": [{"id": 9, "name": "Kotlin"}]})
    assert res.json()["skills"][0]["id"] == 9


def test_rejects_non_pdf(client):
    res = client.post("/extract", files={"file": ("cv.txt", b"hello", "text/plain")})
    assert res.status_code == 415


def test_rejects_bad_catalog(client):
    res = client.post("/extract", files={"file": ("cv.pdf", make_pdf("SKILLS\nJava"), "application/pdf")},
                      data={"catalog": "not json"})
    assert res.status_code == 422
