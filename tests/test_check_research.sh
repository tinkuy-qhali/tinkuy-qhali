#!/usr/bin/env bash
# Test of tools/check_research.py: a valid report passes, a broken one fails for the right reasons,
# the template is skipped, and the consolidated report is checked by its own rules.
set -u
cd "$(dirname "$0")/.."
tmp=".tq-tmp/check_research.$$"; mkdir -p "$tmp"
pass=0; fail=0
check() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then echo "ok   $name"; pass=$((pass+1)); else echo "FAIL $name"; fail=$((fail+1)); fi; }

python tests/fixtures/make_check_research_fixtures.py "$tmp"

check "valid report passes"                 python tools/check_research.py "$tmp/07-espejos.md"

out=$(python tools/check_research.py "$tmp/08-roto.md" 2>&1); rc=$?
check "broken report fails"                 test $rc -ne 0
check "  detects word limit"                grep -q "palabras (máximo 400" <<<"$out"
check "  detects bullet without URL"        grep -q "hallazgo sin URL" <<<"$out"
check "  detects bullet without date"       grep -q "hallazgo sin fecha" <<<"$out"
check "  detects <2 new sources"            grep -q "Fuentes nuevas' con 1" <<<"$out"
check "  detects missing section"           grep -q "Riesgos y provisional" <<<"$out"
check "  detects CRLF"                      grep -q "CRLF" <<<"$out"
check "  detects non-ISO frontmatter date"  grep -q "fecha no es ISO" <<<"$out"

cp docs/research/_plantilla.md "$tmp/_plantilla.md"
out=$(python tools/check_research.py "$tmp/_plantilla.md" 2>&1); rc=$?
check "template skipped"                    test $rc -ne 0
check "  with explicit message"             grep -q "no hay informes" <<<"$out"

check "consolidated report passes"          python tools/check_research.py "$tmp/00-informe-investigacion.md"
check "consolidated with <20 rows fails"    bash -c "! python tools/check_research.py '$tmp/00-corto.md'"

rm -f "$tmp"/*.md; rmdir "$tmp"
echo "check_research tests: $pass passed, $fail failed"
test $fail -eq 0
