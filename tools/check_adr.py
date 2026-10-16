#!/usr/bin/env python3
"""Validate the ADRs in docs/adr/ (Phase 2 acceptance; format inspired by MADR, adapted to this repo).

Every *.md in docs/adr/ except README.md is an ADR and must:
  - be named ^\\d{4}-[a-z0-9-]+\\.md$ with a unique, consecutive number (no gaps from 0000)
  - have exactly one H1 (outside fenced code blocks) "# ADR NNNN — Título" where NNNN matches the file name
  - have the bullets "- **Estado:**" and "- **Fecha:**" within the 6 lines after the title; Fecha is a real ISO date
  - have an Estado that starts with one of: propuesto, aceptado, superseded, rechazado, obsoleto
  - have the sections "## Contexto", "## Decisión" (or "## Votación", alignment ADR) and "## Consecuencias", each once
  - if Estado starts with "superseded", name an existing superseding ADR ("por ADR NNNN") that declares "- **Supersede:**"
  - if it declares "- **Supersede:** ADR NNNN", that ADR must exist and be marked superseded
  - use LF line endings
Usage: python tools/check_adr.py [docs/adr]     Exit 0 when every ADR passes. Stdlib only.
"""
from __future__ import annotations

import re
import sys
from datetime import date
from pathlib import Path

NAME_RE = re.compile(r"^(\d{4})-[a-z0-9-]+\.md$")
TITLE_RE = re.compile(r"^# ADR (\d{4}) — \S")
STATES = ("propuesto", "aceptado", "superseded", "rechazado", "obsoleto")
SECTIONS = (("## Contexto",), ("## Decisión", "## Votación"), ("## Consecuencias",))
IGNORED = {"README.md"}


def body_lines(text: str) -> list[str]:
    """Lines outside fenced code blocks (``` ... ```)."""
    out, fenced = [], False
    for ln in text.splitlines():
        if ln.strip().startswith("```"):
            fenced = not fenced
            continue
        if not fenced:
            out.append(ln)
    return out


def meta_of(text: str) -> dict[str, str]:
    meta: dict[str, str] = {}
    for ln in body_lines(text):
        m = re.match(r"^- \*\*(Estado|Fecha|Supersede):\*\*\s*(.*)$", ln)
        if m and m.group(1) not in meta:
            meta[m.group(1)] = m.group(2).strip()
    return meta


def valid_iso(s: str) -> bool:
    m = re.search(r"\d{4}-\d{2}-\d{2}", s)
    if not m:
        return False
    try:
        date.fromisoformat(m.group(0))
        return True
    except ValueError:
        return False


def check_one(path: Path, all_meta: dict[str, dict[str, str]]) -> list[str]:
    errs: list[str] = []
    m = NAME_RE.match(path.name)
    if not m:
        return ["nombre no sigue NNNN-slug.md (minúsculas, guiones)"]
    num = m.group(1)
    raw = path.read_text(encoding="utf-8", newline="")
    if "\r" in raw:
        errs.append("contiene CRLF; se exige LF")
    text = raw.replace("\r\n", "\n")
    lines = body_lines(text)
    h1_idx = [i for i, ln in enumerate(lines) if ln.startswith("# ")]
    if len(h1_idx) != 1:
        errs.append(f"debe tener exactamente un H1 (tiene {len(h1_idx)})")
    else:
        t = TITLE_RE.match(lines[h1_idx[0]])
        if not t:
            errs.append("el H1 debe ser '# ADR NNNN — Título'")
        elif t.group(1) != num:
            errs.append(f"el número del H1 ({t.group(1)}) no coincide con el archivo ({num})")
        head = lines[h1_idx[0] + 1 : h1_idx[0] + 7]
        if not any(ln.startswith("- **Estado:**") for ln in head):
            errs.append("'- **Estado:**' debe estar en las 6 líneas siguientes al título")
        if not any(ln.startswith("- **Fecha:**") for ln in head):
            errs.append("'- **Fecha:**' debe estar en las 6 líneas siguientes al título")
    meta = meta_of(text)
    estado = meta.get("Estado", "").lower()
    if not estado:
        errs.append("falta '- **Estado:**'")
    elif not estado.startswith(STATES):
        errs.append(f"Estado debe empezar por {', '.join(STATES)} (tiene '{estado[:30]}')")
    if estado.startswith("superseded"):
        ref = re.search(r"por (?:el )?adr (\d{4})", estado)
        if not ref:
            errs.append("un ADR superseded debe decir 'por ADR NNNN'")
        elif ref.group(1) not in all_meta:
            errs.append(f"superseded por ADR {ref.group(1)}, que no existe")
        elif num not in all_meta[ref.group(1)].get("Supersede", ""):
            errs.append(f"el ADR {ref.group(1)} no declara '- **Supersede:** ADR {num}'")
    fecha = meta.get("Fecha", "")
    if not fecha:
        errs.append("falta '- **Fecha:**'")
    elif not valid_iso(fecha):
        errs.append(f"Fecha no es una fecha ISO válida ('{fecha[:20]}')")
    for alts in SECTIONS:
        n = sum(1 for ln in lines if any(ln.strip() == a or ln.strip().startswith(a + " ") for a in alts))
        if n != 1:
            errs.append(f"la sección '{' o '.join(alts)}' debe aparecer exactamente una vez (aparece {n})")
    for ref in re.findall(r"ADR (\d{4})", meta.get("Supersede", "")):
        if ref not in all_meta:
            errs.append(f"supersede al ADR {ref}, que no existe")
        elif not all_meta[ref].get("Estado", "").lower().startswith("superseded"):
            errs.append(f"supersede al ADR {ref}, pero ese ADR no está marcado superseded")
    return errs


def main(argv: list[str]) -> int:
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8")
    root = Path(argv[1]) if len(argv) > 1 else Path(__file__).resolve().parent.parent / "docs" / "adr"
    files = sorted(p for p in root.glob("*.md") if p.name not in IGNORED)
    if not files:
        print("check_adr: no hay ADRs", file=sys.stderr)
        return 1
    all_meta = {p.name[:4]: meta_of(p.read_text(encoding="utf-8")) for p in files if NAME_RE.match(p.name)}
    failed = 0
    for p in files:
        errs = check_one(p, all_meta)
        print(f"[{'OK ' if not errs else 'FAIL'}] {p.name}")
        for e in errs:
            print(f"       - {e}")
        failed += bool(errs)
    nums = [int(p.name[:4]) for p in files if NAME_RE.match(p.name)]
    extra = 0
    if nums:
        gaps = sorted(set(range(0, max(nums) + 1)) - set(nums))
        dups = sorted({n for n in nums if nums.count(n) > 1})
        if gaps:
            print(f"[FAIL] numeración con huecos: {gaps}"); extra += 1
        if dups:
            print(f"[FAIL] números duplicados: {dups}"); extra += 1
    print(f"check_adr: {len(files) - failed}/{len(files)} ADRs válidos" + (f"; {extra} problema(s) de numeración" if extra else ""))
    return 1 if (failed or extra) else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
