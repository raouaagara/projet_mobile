# ─────────────────────────────────────────────
#  CatchOPP – Skill Extractor AI (FastAPI + multilingual embedding model)
# ─────────────────────────────────────────────
FROM python:3.12-slim

WORKDIR /app
ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    SKILL_MODEL_DIR=/app/models

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY app app
COPY data data

# Bake the model into the image so the container works offline (~240MB)
RUN python -c "from app.semantic import SemanticModel; assert SemanticModel().load()"

RUN useradd --create-home catchopp && chown -R catchopp /app
USER catchopp

EXPOSE 8093
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8093"]
