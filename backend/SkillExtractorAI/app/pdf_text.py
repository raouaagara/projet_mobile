"""PDF → text with PyMuPDF (keeps reading order for multi-column CVs)."""
from __future__ import annotations

import pymupdf

from .text_utils import clean_pdf_text


class PdfError(ValueError):
    pass


def pdf_to_text(data: bytes) -> str:
    try:
        doc = pymupdf.open(stream=data, filetype="pdf")
    except Exception as e:  # noqa: BLE001 - any parsing error = invalid PDF
        raise PdfError(f"Not a readable PDF: {e}") from e
    try:
        if doc.is_encrypted and not doc.authenticate(""):
            raise PdfError("The PDF is password-protected.")
        pages = [page.get_text("text", sort=True) for page in doc]
    finally:
        doc.close()
    return clean_pdf_text("\n".join(pages))
