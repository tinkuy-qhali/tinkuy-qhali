#!/usr/bin/env bash
# Acceptance test for Phase 0.6 (spec: "Criterio de aceptación"). Runs on the host with Git Bash; every pipeline
# check executes inside the container. Each line must pass before Phase 1 starts.
set -u
export MSYS_NO_PATHCONV=1   # Git Bash on Windows must not rewrite /workspace, /tmp, /opt into C:... paths
cd "$(dirname "$0")/.."
pass=0; fail=0; skip=0
check() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then echo "PASS  $name"; pass=$((pass+1)); else echo "FAIL  $name"; fail=$((fail+1)); fi; }
skipif() { echo "SKIP  $1 ($2)"; skip=$((skip+1)); }
run() { docker compose run --rm -T pipeline "$@"; }

ORG="${TQ_ORG:-tinkuy-qhali}"

# --- container -----------------------------------------------------------------------------------------------------
check "image exists"                                   docker image inspect tinkuy-qhali:local
check "Rscript --version inside container"             run Rscript --version
check "R stack loads (arrow, duckdb, sf, targets)"     run Rscript -e 'library(arrow); library(duckdb); library(sf); library(targets)'
check "python + duckdb + pyarrow"                      run python -c "import duckdb, pyarrow, polars; print('ok')"
check "dvc --version"                                  run dvc --version
check "quarto --version"                               run quarto --version
check "julia --version"                                run julia --version
check "JuliaCall::julia_setup() works"                 run Rscript -e 'JuliaCall::julia_setup(installJulia = FALSE); stopifnot(JuliaCall::julia_eval("1+1") == 2); cat("ok\n")'
check "claude --version inside container"              run claude --version
check "runs as non-root user"                          bash -c '[ "$(docker compose run --rm -T pipeline id -u)" = "1000" ]'
check "raw/ volume is writable"                        run bash -c 'touch /workspace/raw/.write-test && rm /workspace/raw/.write-test'
check "profile_machine.py runs inside container"       run python tools/profile_machine.py --quiet --out /tmp/mp.json
check "lockfiles committed (renv, uv, julia)"          bash -c 'test -f env/r/renv.lock && test -f env/python/uv.lock && test -f env/julia/Manifest.toml'

# --- GitHub / site --------------------------------------------------------------------------------------------------
if gh api "orgs/$ORG" >/dev/null 2>&1; then
  check "repo $ORG/tinkuy-qhali exists and is public"  bash -c "[ \"\$(gh repo view $ORG/tinkuy-qhali --json visibility --jq .visibility)\" = PUBLIC ]"
  check "repo $ORG/tinkuy-qhali-cdm exists"            gh repo view "$ORG/tinkuy-qhali-cdm"
  check "repo $ORG/tinkuy-qhali-registry exists"       gh repo view "$ORG/tinkuy-qhali-registry"
  check "main branch protected"                        gh api "repos/$ORG/tinkuy-qhali/branches/main/protection"
  check "site online (200)"                            bash -c "curl -sIL https://$ORG.github.io/tinkuy-qhali/ | grep -q '^HTTP/.* 200'"
else
  skipif "GitHub org/repos/site" "org $ORG not found yet"
fi

# --- DVC / registry -------------------------------------------------------------------------------------------------
if [ -f .dvc/config ] && grep -q "remote" .dvc/config; then
  check "dvc status clean against remote"             run dvc status -c
  POINTER=$(ls "${TQ_REGISTRY_DIR:-../tinkuy-qhali-registry}"/pointers/*.json 2>/dev/null | head -1 || true)
  check "first ENDES pointer exists in registry"      bash -c "test -n '$POINTER'"
  check "dvc pull in clean clone recovers file + hash" bash -c 'tmp=$(mktemp -d) && git clone -q . "$tmp/c" && cp .dvc/config.local "$tmp/c/.dvc/" 2>/dev/null; docker compose run --rm -T -v "$tmp/c":/clean -w /clean pipeline bash -c "dvc pull -q && sha256sum -c raw/manifest.sha256"'
else
  skipif "DVC remote + first pull" "no DVC remote configured yet"
fi

# --- Zenodo Sandbox -------------------------------------------------------------------------------------------------
check "Zenodo Sandbox has a tinkuy-qhali record with DOI" bash -c 'curl -s "https://sandbox.zenodo.org/api/records?q=tinkuy-qhali&size=1" | python -c "import json,sys; d=json.load(sys.stdin); hits=d[\"hits\"][\"hits\"]; assert hits and hits[0][\"doi\"], \"no record\""'

echo "---- $pass passed, $fail failed, $skip skipped ----"
test "$fail" -eq 0
