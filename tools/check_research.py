#!/usr/bin/env python3
"""Validate the Phase 1 research reports in docs/research/ (spec: PROMPT v4, Fase 1).

Rules for NN-<tema>.md (NN = 01..26):
  - file name ^\\d{2}-[a-z0-9-]+\\.md$ ; files starting with "_" are templates and are skipped
  - YAML-ish frontmatter with keys item, titulo, modelo, esfuerzo, fecha (ISO), estado
  - one H1 and the sections: Pregunta, Hallazgos, Decisión propuesta, Riesgos y provisional, Fuentes nuevas
  - <= MAX_WORDS words, counting the body only (no frontmatter) and ignoring URL tokens
  - every bullet in "Hallazgos" carries >= 1 http(s) URL and >= 1 ISO date, unless tagged [provisional]
  - "Fuentes nuevas" has >= 2 bullets, each with a URL
Rules for 00-informe-investigacion.md:
  - no word limit; needs a "Tabla de decisiones" with >= MIN_DECISION_ROWS table rows
    and the five final questions answered (one heading or bold label each).
Usage: python tools/check_research.py [path ...]   (default: docs/research/*.md)
Exit code 0 when every file passes.  Standard library only; LF-safe on Windows.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

MAX_WORDS = 400
MIN_NEW_SOURCES = 2
MIN_DECISION_ROWS = 20
REQUIRED_KEYS = ("item", "titulo", "modelo", "esfuerzo", "fecha", "estado")
REQUIRED_SECTIONS = ("Pregunta", "Hallazgos", "Decisión propuesta", "Riesgos y provisional", "Fuentes nuevas")
FIVE_QUESTIONS = ("modelo de datos", "monorepo", "R o Python", "otro repo", "términos conocidos")
URL_RE = re.compile(r"https?://\S+")
DATE_RE = re.compile(r"\b\d{4}-\d{2}-\d{2}\b")
NAME_RE = re.compile(r"^\d{2}-[a-z0-9-]+\.md$")


def split_frontmatter(text: str) -> tuple[dict[str, str], str]:
    if not text.startswith("---\n"):
        return {}, text
    end = text.find("\n---\n", 4)
    if end < 0:
        return {}, text
    meta: dict[str, str] = {}
    for line in text[4:end].splitlines():
        if ":" in line:
            k, v = line.split(":", 1)
            meta[k.strip()] = v.strip()
    return meta, text[end + 5:]


def sections(body: str) -> dict[str, str]:
    out: dict[str, str] = {}
    current = None
    for line in body.splitlines():
        m = re.match(r"^##\s+(.*?)\s*$", line)
        if m:
            current = m.group(1)
            out[current] = ""
        elif current is not None:
            out[current] += line + "\n"
    return out


def bullets(block: str) -> list[str]:
    items: list[str] = []
    for line in block.splitlines():
        if re.match(r"^\s*[-*]\s+", line):
            items.append(line)
        elif items and re.match(r"^\s{2,}\S", line):
            items[-1] += " " + line.strip()
    return items


def word_count(body: str) -> int:
    return sum(1 for tok in body.split() if not tok.startswith(("http://", "https://", "(http")))


def check_report(path: Path) -> list[str]:
    errors: list[str] = []
    if not NAME_RE.match(path.name):
        errors.append("nombre de archivo no sigue NN-tema.md (minúsculas, guiones)")
    text = path.read_text(encoding="utf-8", newline="")
    if "\r" in text:
        errors.append("contiene CRLF; se exige LF")
        text = text.replace("\r\n", "\n")
    meta, body = split_frontmatter(text)
    for key in REQUIRED_KEYS:
        if key not in meta or not meta[key]:
            errors.append(f"frontmatter sin clave '{key}'")
    if "fecha" in meta and not DATE_RE.fullmatch(meta["fecha"]):
        errors.append("frontmatter: fecha no es ISO AAAA-MM-DD")
    if "item" in meta and meta["item"].zfill(2) != path.name[:2]:
        errors.append(f"frontmatter item={meta['item']} no coincide con el prefijo {path.name[:2]}")
    if len(re.findall(r"^#\s+\S", body, flags=re.M)) != 1:
        errors.append("debe tener exactamente un H1")
    secs = sections(body)
    for name in REQUIRED_SECTIONS:
        if name not in secs:
            errors.append(f"falta la sección '## {name}'")
    n = word_count(body)
    if n > MAX_WORDS:
        errors.append(f"{n} palabras (máximo {MAX_WORDS}, sin contar URL)")
    for b in bullets(secs.get("Hallazgos", "")):
        if "[provisional]" in b:
            continue
        if not URL_RE.search(b):
            errors.append(f"hallazgo sin URL: {b[:70]}…")
        if not DATE_RE.search(b):
            errors.append(f"hallazgo sin fecha ISO: {b[:70]}…")
    if "Hallazgos" in secs and not bullets(secs["Hallazgos"]):
        errors.append("'Hallazgos' no tiene viñetas")
    new = [b for b in bullets(secs.get("Fuentes nuevas", "")) if URL_RE.search(b)]
    if len(new) < MIN_NEW_SOURCES:
        errors.append(f"'Fuentes nuevas' con {len(new)} URL (mínimo {MIN_NEW_SOURCES})")
    if "Decisión propuesta" in secs and not bullets(secs["Decisión propuesta"]):
        errors.append("'Decisión propuesta' no tiene viñetas")
    return errors


def check_consolidated(path: Path) -> list[str]:
    errors: list[str] = []
    text = path.read_text(encoding="utf-8", newline="")
    if "\r" in text:
        errors.append("contiene CRLF; se exige LF")
        text = text.replace("\r\n", "\n")
    if "Tabla de decisiones" not in text:
        errors.append("falta 'Tabla de decisiones'")
    rows = [ln for ln in text.splitlines() if ln.startswith("|") and not re.match(r"^\|\s*-", ln)]
    rows = [r for r in rows if not re.match(r"^\|\s*(Ítem|Item|#)\b", r, flags=re.I)]
    if len(rows) < MIN_DECISION_ROWS:
        errors.append(f"tabla con {len(rows)} filas de datos (mínimo {MIN_DECISION_ROWS})")
    low = text.lower()
    for q in FIVE_QUESTIONS:
        if q.lower() not in low:
            errors.append(f"no responde la pregunta sobre '{q}'")
    if not URL_RE.search(text):
        errors.append("sin ninguna URL")
    return errors


def main(argv: list[str]) -> int:
    for stream in (sys.stdout, sys.stderr):  # Windows consoles default to cp1252; grep in tests expects UTF-8
        stream.reconfigure(encoding="utf-8")
    root = Path(__file__).resolve().parent.parent
    paths = [Path(p) for p in argv[1:]] or sorted((root / "docs" / "research").glob("*.md"))
    paths = [p for p in paths if not p.name.startswith("_")]
    if not paths:
        print("check_research: no hay informes que validar", file=sys.stderr)
        return 1
    failed = 0
    for p in paths:
        errs = check_consolidated(p) if p.name.startswith("00-") else check_report(p)
        status = "OK " if not errs else "FAIL"
        print(f"[{status}] {p.name}")
        for e in errs:
            print(f"       - {e}")
        failed += bool(errs)
    print(f"check_research: {len(paths) - failed}/{len(paths)} informes válidos")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
