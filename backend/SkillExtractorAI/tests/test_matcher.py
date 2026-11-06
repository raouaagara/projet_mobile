"""Match score between a freelancer's skills and jobs, with the real multilingual model."""
import pytest
from fastapi.testclient import TestClient

from app.extractor import SkillExtractor
from app.lexicon import load_lexicon
from app.main import app, model
from app.matcher import Job, Matcher

FLUTTER_JOB = Job(1, "Restaurant ordering app. We need a Flutter developer to build an Android and iOS app "
                     "with online ordering and Firebase notifications.", ["Flutter"])
API_JOB = Job(2, "Inventory REST API with Spring Boot and MySQL, deployed with Docker.", ["Spring Boot", "MySQL"])
FRENCH_JOB = Job(3, "Application mobile de réservation pour une salle de sport, en Flutter avec Firebase.", [])
MOVING_JOB = Job(4, "Help us move our office furniture next week.", [])


@pytest.fixture(scope="module")
def matcher():
    model.load()
    return Matcher(SkillExtractor(load_lexicon(), model))


def scores(matcher, profile, jobs):
    return {r.id: r for r in matcher.match(profile, jobs)}


def test_right_freelancer_scores_high(matcher):
    res = scores(matcher, ["Flutter", "Dart", "Firebase"], [FLUTTER_JOB, API_JOB])
    assert res[1].score >= 70 and res[2].score < 20
    assert res[1].matched == ["Flutter", "Firebase"]  # required first
    assert set(res[1].related) == {"Android", "iOS"}  # same field (Mobile) as Flutter
    assert set(res[2].missing) >= {"Spring Boot", "MySQL", "Docker"}


def test_aliases_count_as_the_same_skill(matcher):
    job = Job(5, "Backend in NodeJS and Postgres", ["Node.js"])
    res = scores(matcher, ["nodejs", "PostgreSQL"], [job])[5]
    assert res.missing == [] and res.score >= 85


def test_french_job_text_is_understood(matcher):
    res = scores(matcher, ["Flutter", "Firebase"], [FRENCH_JOB])[3]
    assert {"Flutter", "Firebase"} <= set(res.matched) and res.score >= 60


def test_related_skill_gives_partial_credit(matcher):
    job = Job(6, "Delivery app", ["React Native"])
    res = scores(matcher, ["Flutter"], [job])[6]
    assert res.related == ["React Native"] and 30 <= res.score <= 60


def test_job_without_skills_is_capped_and_empty_profile_is_zero(matcher):
    assert scores(matcher, ["Flutter"], [MOVING_JOB])[4].score <= 50
    assert all(r.score == 0 for r in matcher.match([], [FLUTTER_JOB, API_JOB]))


def test_match_endpoint_keeps_order():
    with TestClient(app) as client:
        model.load()
        res = client.post("/match", json={
            "profile": ["Java", "Spring Boot", "MySQL"],
            "jobs": [{"id": 1, "text": FLUTTER_JOB.text, "requiredSkills": ["Flutter"]},
                     {"id": 2, "text": API_JOB.text, "requiredSkills": ["Spring Boot", "MySQL"]}],
        })
    assert res.status_code == 200
    body = res.json()
    assert [j["id"] for j in body] == [1, 2]
    assert body[1]["score"] > body[0]["score"] and {"Spring Boot", "MySQL"} <= set(body[1]["matched"])
