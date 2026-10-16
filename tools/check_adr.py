#!/usr/bin/env python3
"""Validate the ADRs in docs/adr/ (Phase 2 acceptance; format inspired by MADR, adapted to this repo).

Each docs/adr/NNNN-<slug>.md must:
  - be named ^\\d{4}-[a-z0-9-]+\\.md$ with a unique, consecutive number (no gaps from 0000)
  - have exactly one H1 starting with "# ADR NNNN — " where NNNN matches the file name
  - have the bullets "- **Estado:**" and "- **Fecha:**" (ISO date) right after the title
  - have an Estado that starts with one of: propuesto, aceptado, superseded, rechazado, obsoleto
  - have the sections "## Contexto", "## Decisión" (or "## Votación", for the alignment ADR) and "## Consecuencias", each once
  - if Estado starts with "superseded", name the superseding ADR ("por ADR NNNN")
  - if it declares "- **Supersede:** ADR NNNN", that ADR must exist and be marked superseded
  - use LF line endings
Usage: python tools/check_adr.py [docs/adr]     Exit 0 when every ADR passes. Stdlib only.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

NAME_RE = re.compile(r"^(\d{4})-[a-z0-9-]+\.md$")
TITLE_RE = re.compile(r"^# ADR (\d{4}) — \S")
DATE_RE = re.compile(r"\b\d{4}-\d{2}-\d{2}\b")
STATES = ("propuesto", "aceptado", "superseded", "rechazado", "obsoleto")
SECTIONS = (("## Contexto",), ("## Decisión", "## Votación"), ("## Consecuencias",))  # alternatives per slot


def check_one(path: Path, all_states: dict[str, str]) -> list[str]:
    errs: list[str] = []
    m = NAME_RE.match(path.name)
    if not m:
        return ["nombre no sigue NNNN-slug.md"]
    num = m.group(1)
    raw = path.read_text(encoding="utf-8", newline="")
    if "\r" in raw:
        errs.append("contiene CRLF; se exige LF")
    text = raw.replace("\r\n", "\n")
    lines = text.splitlines()
    h1 = [ln for ln in lines if ln.startswith("# ")]
    if len(h1) != 1:
        errs.append(f"debe tener exactamente un H1 (tiene {len(h1)})")
    else:
        t = TITLE_RE.match(h1[0])
        if not t:
            errs.append("el H1 debe ser '# ADR NNNN — Título'")
        elif t.group(1) != num:
            errs.append(f"el número del H1 ({t.group(1)}) no coincide con el archivo ({num})")
    estado = next((ln for ln in lines if ln.startswith("- **Estado:**")), None)
    fecha = next((ln for ln in lines if ln.startswith("- **Fecha:**")), None)
    if not estado:
        errs.append("falta '- **Estado:**'")
    else:
        val = estado.split("**Estado:**", 1)[1].strip().lower()
        if not val.startswith(STATES):
            errs.append(f"Estado debe empezar por {', '.join(STATES)} (tiene '{val[:30]}')")
        if val.startswith("superseded") and not re.search(r"por (el )?adr \d{4}", val):  # val is lowercased
            errs.append("un ADR superseded debe decir 'por ADR NNNN'")
    if not fecha:
        errs.append("falta '- **Fecha:**'")
    elif not DATE_RE.search(fecha):
        errs.append("Fecha no es ISO AAAA-MM-DD")
    for alts in SECTIONS:
        n = sum(1 for ln in lines if any(ln.strip() == a or ln.strip().startswith(a + " ") for a in alts))
        if n != 1:
            errs.append(f"la sección '{' o '.join(alts)}' debe aparecer exactamente una vez (aparece {n})")
    sup = next((ln for ln in lines if ln.startswith("- **Supersede:**")), None)
    if sup:
        for ref in re.findall(r"ADR (\d{4})", sup):
            if ref not in all_states:
                errs.append(f"supersede al ADR {ref}, que no existe")
            elif not all_states[ref].startswith("superseded"):
                errs.append(f"supersede al ADR {ref}, pero ese ADR no está marcado superseded")
    return errs


def main(argv: list[str]) -> int:
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8")
    root = Path(argv[1]) if len(argv) > 1 else Path(__file__).resolve().parent.parent / "docs" / "adr"
    files = sorted(p for p in root.glob("*.md") if NAME_RE.match(p.name))
    if not files:
        print("check_adr: no hay ADRs", file=sys.stderr)
        return 1
    states: dict[str, str] = {}
    for p in files:
        for ln in p.read_text(encoding="utf-8").splitlines():
            if ln.startswith("- **Estado:**"):
                states[p.name[:4]] = ln.split("**Estado:**", 1)[1].strip().lower()
                break
    failed = 0
    nums = [int(p.name[:4]) for p in files]
    gaps = sorted(set(range(0, max(nums) + 1)) - set(nums))
    dups = sorted({n for n in nums if nums.count(n) > 1})
    for p in files:
        errs = check_one(p, states)
        print(f"[{'OK ' if not errs else 'FAIL'}] {p.name}")
        for e in errs:
            print(f"       - {e}")
        failed += bool(errs)
    if gaps:
        print(f"[FAIL] numeración con huecos: {gaps}"); failed += 1
    if dups:
        print(f"[FAIL] números duplicados: {dups}"); failed += 1
    print(f"check_adr: {len(files) - failed if not (gaps or dups) else len(files) - failed}/{len(files)} ADRs válidos" + ("" if not (gaps or dups) else " (numeración inválida)"))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
