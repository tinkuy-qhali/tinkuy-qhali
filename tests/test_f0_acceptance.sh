#!/usr/bin/env bash
# Acceptance test for Phase 0 closure (ADR 0000 §0.5, F0-cierre). Run from repo root with Git Bash.
# Why a script: the spec forbids declaring anything critical done without executing its test.
set -u
pass=0; fail=0
check() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then echo "PASS  $name"; pass=$((pass+1)); else echo "FAIL  $name"; fail=$((fail+1)); fi; }

check "profile_machine.py runs and writes machine-profile.json" bash -c 'python tools/profile_machine.py --quiet --out machine-profile.json && test -f machine-profile.json'
check "machine-profile.json is gitignored"                      git check-ignore -q machine-profile.json
check "raw/ is gitignored"                                      git check-ignore -q raw/anything.zip
check "user settings.json is valid JSON with effortLevel"       python -c "import json,os; s=json.load(open(os.path.expanduser('~/.claude/settings.json'),encoding='utf-8')); assert s['effortLevel']=='high'"
check "user settings.json has deny rule for rm -rf"             python -c "import json,os; s=json.load(open(os.path.expanduser('~/.claude/settings.json'),encoding='utf-8')); assert 'Bash(rm -rf:*)' in s['permissions']['deny']"
check "user settings.json has ask rule for git push"            python -c "import json,os; s=json.load(open(os.path.expanduser('~/.claude/settings.json'),encoding='utf-8')); assert 'Bash(git push:*)' in s['permissions']['ask']"
check "settings backup exists"                                  test -f "$HOME/.claude/settings.json.bak-20261016"
check "global excludesfile configured and ignores worktrees"    bash -c 'f=$(git config --global core.excludesfile) && grep -q "^.claude/worktrees/$" "$f" && grep -q "^tmpclaude-\*$" "$f"'
check "at least 6 ADRs present"                                 bash -c 'test "$(ls docs/adr/*.md | wc -l)" -ge 6'
check "every ADR has Estado and Fecha"                          bash -c 'for f in docs/adr/*.md; do grep -q "^- \*\*Estado:\*\*" "$f" && grep -q "^- \*\*Fecha:\*\*" "$f" || exit 1; done'
check "derived limits follow spec (cores-1, ~75% RAM)"          python -c "import json; d=json.load(open('machine-profile.json')); c=d['cpu']['logical_cores']; r=d['ram']['total_gb']; assert d['derived']['container_cpus']==c-1; assert abs(d['derived']['container_memory_gb']-0.75*r)<0.2"
check "plan copy archived in agent-log"                         test -f docs/agent-log/2026-10-16-fase0-plan.md
check "Claude Code >= 2.1.257 (project files ignore bypass)"    python -c "import json; v=json.load(open('machine-profile.json'))['software']['claude_code'].split()[0].split('.'); assert tuple(map(int,v))>=(2,1,257), v"

echo "---- $pass passed, $fail failed ----"
test "$fail" -eq 0
