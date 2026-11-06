"""Multilingual sentence-embedding model (FR/EN and 50+ other languages).

paraphrase-multilingual-MiniLM-L12-v2 maps phrases with the same meaning close to
each other *across languages* ("apprentissage automatique" ≈ "machine learning").
It runs locally with ONNX Runtime (no API key, no GPU needed).
"""
from __future__ import annotations

import logging
import os
import threading
from pathlib import Path

import numpy as np

log = logging.getLogger(__name__)

MODEL_NAME = os.getenv("SKILL_MODEL", "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2")
MODEL_DIR = os.getenv("SKILL_MODEL_DIR", str(Path(__file__).resolve().parent.parent / "models"))


class SemanticModel:
    def __init__(self, name: str = MODEL_NAME, cache_dir: str = MODEL_DIR) -> None:
        self.name = name
        self.cache_dir = cache_dir
        self._model = None
        self._error: str | None = None
        self._cache: dict[str, np.ndarray] = {}
        self._lock = threading.Lock()

    def load(self) -> bool:
        """Loads (downloads on first run) the model. Returns False if unavailable."""
        if self._model is not None:
            return True
        try:
            from fastembed import TextEmbedding

            self._model = TextEmbedding(self.name, cache_dir=self.cache_dir)
            self._error = None
            log.info("Semantic model loaded: %s", self.name)
            return True
        except Exception as e:  # noqa: BLE001 - offline, corrupted cache...
            self._error = str(e)
            log.warning("Semantic model unavailable, exact matching only: %s", e)
            return False

    @property
    def ready(self) -> bool:
        return self._model is not None

    @property
    def error(self) -> str | None:
        return self._error

    def embed(self, texts: list[str]) -> np.ndarray:
        """L2-normalized embeddings (rows), cached per text."""
        if not texts:
            return np.zeros((0, 384), np.float32)
        if len(self._cache) > 20000:  # keep memory bounded
            self._cache.clear()
        missing = [t for t in dict.fromkeys(texts) if t not in self._cache]
        if missing:
            with self._lock:
                vectors = list(self._model.embed(missing, batch_size=64))
            for text, vec in zip(missing, vectors):
                vec = np.asarray(vec, dtype=np.float32)
                self._cache[text] = vec / (np.linalg.norm(vec) or 1.0)
        return np.stack([self._cache[t] for t in texts])
