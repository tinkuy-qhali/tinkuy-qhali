#!/usr/bin/env bash
# Acceptance test of Phase 2 (architecture + ADRs), from docs/agent-log/2026-10-16-fase0-plan.md:
#   - docs/architecture/00-flujo-agentico.md and 01-ecosistema.md exist, each with a ```mermaid block using @{ shape }
#     and the ISO classDef block from docs/style/mermaid-iso5807.md, plus a "Fuente:" line with a validation date
#   - every mermaid block in docs/ was validated (we check structure here; rendering is validated with the Mermaid MCP
#     or mmdc and recorded in the Fuente: line — see docs/style/mermaid-iso5807.md)
#   - tools/check_adr.py passes on docs/adr/ and its own test suite passes; ADRs 0008..0013 exist
#   - six policies in docs/policies/ with the mandatory sections and >= 6 rules each; docs/preservation/ has 3 files
#   - docs/reviews/f2-adversarial.md exists and its author response reports 0 open critical findings
#   - all of the above are LF
# Usage: bash tests/test_f2_acceptance.sh
set -u
cd "$(dirname "$0")/.."
pass=0; fail=0
check() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then echo "ok   $name"; pass=$((pass+1)); else echo "FAIL $name"; fail=$((fail+1)); fi; }

for f in docs/architecture/00-flujo-agentico.md docs/architecture/01-ecosistema.md; do
  check "$f exists"                               test -f "$f"
  check "  has a mermaid block with @{ shape }"   bash -c "grep -q '^\`\`\`mermaid' '$f' && grep -q '@{ shape:' '$f'"
  check "  uses the ISO classDef block"           bash -c "grep -q 'classDef human' '$f' && grep -q 'classDef dec' '$f'"
  check "  has Fuente: line with validation date" bash -c "grep -E '^Fuente:.*validado.*20[0-9]{2}-[0-9]{2}-[0-9]{2}' '$f' | grep -q ."
done
check "style guide exists with mapping table"     bash -c "grep -q 'lin-cyl' docs/style/mermaid-iso5807.md && grep -q 'sl-rect' docs/style/mermaid-iso5807.md"
check "no mermaid block in docs/ lacks @{ shape } (classic syntax banned)" bash -c '
  bad=0; for f in $(grep -rl "^\`\`\`mermaid" docs --include=*.md); do
    awk "/^\`\`\`mermaid/{inb=1;blk=\"\";next} /^\`\`\`/{if(inb){print blk; inb=0}} inb{blk=blk\$0\"\\n\"}" "$f" | grep -q "@{ shape" || { echo "$f"; bad=1; }
  done; test $bad -eq 0'

check "check_adr.py self-test passes"             bash tests/test_check_adr.sh
check "check_adr.py validates docs/adr"           python tools/check_adr.py
for n in 0008 0009 0010 0011 0012 0013 0014; do check "ADR $n exists" bash -c "ls docs/adr/$n-*.md"; done
check "ADR 0001 marked superseded by 0008"        grep -q "superseded por ADR 0008" docs/adr/0001-config-claude-code.md

for p in context hygiene security downstream r-style performance; do
  f="docs/policies/$p.md"
  check "policy $p exists"                        test -f "$f"
  check "  has mandatory sections"                bash -c "for s in '## Propósito' '## Reglas' '## Qué hace el agente y qué no' '## Mecanismos que la hacen cumplir' '## Provisional' '## Fuentes'; do grep -q \"^\$s\" '$f' || exit 1; done"
  check "  has >= 6 rules"                        bash -c "[ \$(grep -cE '^R[0-9]+\.' '$f') -ge 6 ]"
done
check "docs/preservation has 3 files"             bash -c "[ \$(ls docs/preservation/*.md | wc -l) -eq 3 ]"
check "plan-3-2-1 has the loss-scenario table"    grep -qi "RPO" docs/preservation/plan-3-2-1.md

check "adversarial review exists"                 test -f docs/reviews/f2-adversarial.md
check "  author response reports 0 open criticals"  bash -c "grep -qE '^Estado tras correcciones: Críticos abiertos: 0' docs/reviews/f2-adversarial.md"

check "no CRLF in docs/{adr,policies,architecture,preservation,style,reviews}" bash -c '! grep -rl $'"'"'\r'"'"' docs/adr docs/policies docs/architecture docs/preservation docs/style docs/reviews 2>/dev/null | grep -q .'
check "no leftover subagent worktrees"            bash -c '[ "$(git worktree list | grep -c worktrees/agent-)" -eq 0 ]'

echo "f2 acceptance: $pass passed, $fail failed"
test $fail -eq 0
