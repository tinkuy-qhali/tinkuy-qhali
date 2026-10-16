#!/usr/bin/env bash
# Acceptance test of Phase 1 (research), from docs/agent-log/2026-10-16-fase0-plan.md:
#   - >= 27 files in docs/research/ (26 reports + consolidated 00), all LF
#   - tools/check_research.py validates every report (its own test suite passes too)
#   - 00-informe-investigacion.md has the decision table with >= 20 rows and the five answers
#   - benchmarks/run_all.R produced benchmarks/results.parquet (item 22) and results.md exists
#   - no leftover subagent worktrees or worktree-* branches
# Usage: bash tests/test_f1_acceptance.sh        (set TQ_SKIP_DOCKER=1 to skip the parquet readability check)
set -u
cd "$(dirname "$0")/.."
pass=0; fail=0
check() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then echo "ok   $name"; pass=$((pass+1)); else echo "FAIL $name"; fail=$((fail+1)); fi; }

n_reports=$(ls docs/research/[0-9][0-9]-*.md 2>/dev/null | wc -l)
check "docs/research has >= 27 NN-*.md files ($n_reports)"   test "$n_reports" -ge 27
check "26 numbered reports 01..26 present"                   bash -c 'for i in $(seq -w 1 26); do ls docs/research/$i-*.md >/dev/null 2>&1 || exit 1; done'
check "no CRLF in docs/research"                             bash -c '! grep -rl $'"'"'\r'"'"' docs/research/ | grep -q .'
check "check_research.py self-test passes"                   bash tests/test_check_research.sh
check "check_research.py validates every report"             python tools/check_research.py
check "00 has 'Tabla de decisiones' with >= 26 item rows"    bash -c '[ "$(grep -cE "^\| [0-9]+ \|" docs/research/00-informe-investigacion.md)" -ge 26 ]'
check "00 answers the five questions"                        bash -c 'for q in "modelo de datos" "Monorepo o multirepo" "R o Python" "otro repo" "términos conocidos"; do grep -q "$q" docs/research/00-informe-investigacion.md || exit 1; done'
check "benchmarks/run_all.R exists"                          test -f benchmarks/run_all.R
check "benchmarks/results.parquet exists and is non-empty"   bash -c '[ -s benchmarks/results.parquet ]'
check "benchmarks/results.md exists"                         test -f benchmarks/results.md
check "benchmarks/results.csv has >= 10 data rows"           bash -c '[ "$(tail -n +2 benchmarks/results.csv | wc -l)" -ge 10 ]'
if [ "${TQ_SKIP_DOCKER:-0}" != "1" ]; then
  check "results.parquet readable by arrow in the container"  bash -c 'MSYS_NO_PATHCONV=1 docker compose run --rm -T pipeline Rscript -e "stopifnot(nrow(arrow::read_parquet(\"benchmarks/results.parquet\")) >= 10)"'
fi
check "no leftover subagent worktrees"                       bash -c '[ "$(git worktree list | grep -c worktrees/agent-)" -eq 0 ]'
check "no leftover worktree-* branches"                      bash -c '! git branch --list "worktree-*" | grep -q .'
check "ADR 0008 exists (supersedes 0001)"                    grep -q "Supersede:\*\* ADR 0001" docs/adr/0008-config-claude-code-revision.md

echo "f1 acceptance: $pass passed, $fail failed"
test $fail -eq 0
