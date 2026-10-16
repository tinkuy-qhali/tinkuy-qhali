#!/usr/bin/env bash
# Test of tools/check_adr.py: the real ADR set passes; synthetic sets fail for the right reasons.
set -u
cd "$(dirname "$0")/.."
tmp=".tq-tmp/check_adr.$$"; mkdir -p "$tmp"
pass=0; fail=0
check() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then echo "ok   $name"; pass=$((pass+1)); else echo "FAIL $name"; fail=$((fail+1)); fi; }

check "real docs/adr passes"                       python tools/check_adr.py docs/adr

w() { printf '%s\n' "$2" > "$tmp/$1"; }
good='# ADR 0000 — Uno

- **Estado:** aceptado
- **Fecha:** 2026-10-16

## Contexto
x
## Decisión
y
## Consecuencias
z'
w 0000-uno.md "$good"
check "minimal valid ADR passes"                   python tools/check_adr.py "$tmp"

w 0001-dos.md "$(printf '%s' "$good" | sed 's/ADR 0000/ADR 0001/; s/aceptado/en revisión/')"
out=$(python tools/check_adr.py "$tmp" 2>&1); rc=$?
check "unknown Estado fails"                       test $rc -ne 0
check "  message names Estado"                     grep -q "Estado debe empezar" <<<"$out"

w 0001-dos.md "$(printf '%s' "$good" | sed 's/ADR 0000/ADR 0001/; s/aceptado/superseded (sin referencia)/')"
check "superseded without 'por ADR' fails"         bash -c "python tools/check_adr.py '$tmp' 2>&1 | grep -q 'por ADR NNNN'"

w 0001-dos.md "$(printf '%s' "$good" | sed 's/ADR 0000/ADR 0001/' | grep -v '^## Consecuencias')"
check "missing section fails"                      bash -c "python tools/check_adr.py '$tmp' 2>&1 | grep -q 'Consecuencias'"

w 0001-dos.md "$(printf '%s' "$good" | sed 's/ADR 0000/ADR 0002/')"
check "H1 number mismatch fails"                   bash -c "python tools/check_adr.py '$tmp' 2>&1 | grep -q 'no coincide'"

rm -f "$tmp/0001-dos.md"; w 0002-tres.md "$(printf '%s' "$good" | sed 's/ADR 0000/ADR 0002/')"
check "numbering gap fails"                        bash -c "python tools/check_adr.py '$tmp' 2>&1 | grep -q 'huecos'"

rm -f "$tmp/0002-tres.md"
w 0001-dos.md "$(printf '%s' "$good" | sed 's/ADR 0000/ADR 0001/; s/- \*\*Fecha:\*\* 2026-10-16/- **Fecha:** 2026-10-16\n- **Supersede:** ADR 0000/')"
check "supersede of a non-superseded ADR fails"    bash -c "python tools/check_adr.py '$tmp' 2>&1 | grep -q 'no está marcado superseded'"
w 0000-uno.md "$(printf '%s' "$good" | sed 's/aceptado/superseded por ADR 0001/')"
check "consistent supersede chain passes"          python tools/check_adr.py "$tmp"

printf '%s\r\n' "$good" > "$tmp/0000-uno.md"
check "CRLF fails"                                 bash -c "python tools/check_adr.py '$tmp' 2>&1 | grep -q 'CRLF'"

rm -f "$tmp"/*.md; rmdir "$tmp"
echo "check_adr tests: $pass passed, $fail failed"
test $fail -eq 0
