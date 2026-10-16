#!/usr/bin/env bash
# Test of tools/check_adr.py: the real ADR set passes; synthetic sets fail for the right reasons AND with rc != 0.
set -u
cd "$(dirname "$0")/.."
tmp=".tq-tmp/check_adr.$$"; mkdir -p "$tmp"
pass=0; fail=0
check() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then echo "ok   $name"; pass=$((pass+1)); else echo "FAIL $name"; fail=$((fail+1)); fi; }
# fails_with <pattern> <dir>: validator must exit non-zero AND print the pattern
fails_with() { local out; out=$(python tools/check_adr.py "$2" 2>&1); local rc=$?; [ $rc -ne 0 ] && grep -q -- "$1" <<<"$out"; }
w() { printf '%s\n' "$2" > "$tmp/$1"; }
reset() { rm -f "$tmp"/*.md; w 0000-uno.md "$good"; }

check "real docs/adr passes"                           python tools/check_adr.py docs/adr

good='# ADR 0000 — Uno

- **Estado:** aceptado
- **Fecha:** 2026-10-16

## Contexto
x
## Decisión
y
## Consecuencias
z'
reset
check "minimal valid ADR passes"                       python tools/check_adr.py "$tmp"

reset; w 0001-dos.md "$(sed 's/ADR 0000/ADR 0001/; s/aceptado/en revisión/' <<<"$good")"
check "unknown Estado fails (rc!=0)"                   fails_with "Estado debe empezar" "$tmp"

reset; w 0001-dos.md "$(sed 's/ADR 0000/ADR 0001/; s/aceptado/superseded (sin referencia)/' <<<"$good")"
check "superseded without 'por ADR' fails"             fails_with "por ADR NNNN" "$tmp"

reset; w 0001-dos.md "$(sed 's/ADR 0000/ADR 0001/; s/aceptado/superseded por ADR 0099/' <<<"$good")"
check "superseded by nonexistent ADR fails"            fails_with "que no existe" "$tmp"

reset; w 0001-dos.md "$(sed 's/ADR 0000/ADR 0001/' <<<"$good" | grep -v '^## Consecuencias')"
check "missing section fails"                          fails_with "Consecuencias" "$tmp"

reset; w 0001-dos.md "$(sed 's/ADR 0000/ADR 0002/' <<<"$good")"
check "H1 number mismatch fails"                       fails_with "no coincide" "$tmp"

reset; w 0002-tres.md "$(sed 's/ADR 0000/ADR 0002/' <<<"$good")"
check "numbering gap fails"                            fails_with "huecos" "$tmp"

reset; w 0001-dos.md "$(sed 's/ADR 0000/ADR 0001/; s/2026-10-16/2026-99-99/' <<<"$good")"
check "invalid ISO date fails"                         fails_with "fecha ISO válida" "$tmp"

reset; w 0001_Mal_Nombre.md "$good"
check "misnamed file is not skipped"                   fails_with "nombre no sigue" "$tmp"

reset; w 0001-dos.md "$(printf '%s\n' "$good" | sed 's/ADR 0000/ADR 0001/; s/^z$/z\n```\n# no soy un H1\n```/')"
check "H1 inside fenced block is ignored"              python tools/check_adr.py "$tmp"

reset; w 0001-dos.md "$(printf '%s\n' "$good" | sed 's/ADR 0000/ADR 0001/; s/^- \*\*Fecha:\*\* 2026-10-16$/- **Fecha:** 2026-10-16\n- **Supersede:** ADR 0000/')"
check "supersede of a non-superseded ADR fails"        fails_with "no está marcado superseded" "$tmp"
w 0000-uno.md "$(sed 's/aceptado/superseded por ADR 0001/' <<<"$good")"
check "consistent supersede chain passes"              python tools/check_adr.py "$tmp"
w 0001-dos.md "$(sed 's/ADR 0000/ADR 0001/' <<<"$good")"
check "superseded by ADR that lacks Supersede: fails"  fails_with "no declara" "$tmp"

reset; printf '%s\r\n' "$good" > "$tmp/0000-uno.md"
check "CRLF fails"                                     fails_with "CRLF" "$tmp"

rm -f "$tmp"/*.md; rmdir "$tmp"
echo "check_adr tests: $pass passed, $fail failed"
test $fail -eq 0
