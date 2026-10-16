---
item: 14
titulo: Benchmarking agéntico y humano
modelo: sonnet
esfuerzo: medium
fecha: 2026-10-16
estado: borrador
---
# 14 — Benchmarking agéntico y humano

## Pregunta
¿Cómo medir de forma reproducible el desempeño del agente (tareas doradas, costo, permisos, residuos) y la calidad percibida por humanos en las Rondas 1 (fuente sintética) y 2 (ENDES)?

## Hallazgos
- `claude plugin eval` (≥ 2.1.269) usa `evals/<caso>/prompt.md` más `graders/*.md`; graders `regex`, `tool_used`, `tool_order`, `file_exists`, `llm`, `baseline` (sin código propio); 3 corridas por caso, brazo con/sin plugin (Δ), `--json`, salida 0/1/2, `costUsd` (https://code.claude.com/docs/en/plugin-evals, 2026-10-16).
- Cada corrida de `plugin eval` parte de un directorio vacío, sin `CLAUDE.md` ni `.claude/`; Bash exige sandbox del SO, inexistente en Windows nativo: sirve para el disparo de skills, no para tareas sobre el repo (https://code.claude.com/docs/en/plugin-evals, 2026-10-16).
- `claude -p --output-format json` devuelve `total_cost_usd` y uso (estimación del cliente); `--permission-prompts none` deniega lo que pediría permiso y lo lista en `permission_denials` (https://code.claude.com/docs/en/headless, 2026-10-16).
- Hook `PermissionRequest` se dispara cuando una llamada necesita decisión; OpenTelemetry exporta `claude_code.token.usage`, `claude_code.cost.usage` y eventos `tool_decision`, `api_request` (https://code.claude.com/docs/en/hooks, https://code.claude.com/docs/en/monitoring-usage, 2026-10-16).
- El JSONL de transcripciones es formato interno y cambia entre versiones (https://code.claude.com/docs/en/sessions, 2026-10-16). `ccusage` lee datos locales **[no oficial]** (https://github.com/ryoppippi/ccusage, 2026-10-16).
- Anthropic: graders de código donde se pueda, jueces LLM calibrados con humanos, calificar resultado y no camino, leer transcripciones, pass@k y pass^k (75 % por intento ≈ 42 % pass^3) (https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents, 2026-10-16).
- **[no oficial]** SWE-bench separa `FAIL_TO_PASS` y `PASS_TO_PASS` (https://huggingface.co/datasets/princeton-nlp/SWE-bench_Verified, 2026-10-16); HAL publica costo junto a exactitud (https://hal.cs.princeton.edu/, 2026-10-16); Terminal-Bench corre en Harbor con `-k` repeticiones (https://www.tbench.ai/docs, 2026-10-16).
- Rúbricas: JOSS (instalación, ejemplos, tests, guías) y rOpenSci (necesidad, documentación, horas) (https://joss.readthedocs.io/en/latest/review_checklist.html, https://devguide.ropensci.org/reviewtemplate.html, 2026-10-16).

## Decisión propuesta
- Decisión: arnés propio en el contenedor (`claude -p`, graders por script ocultos al agente, 9 tareas × 3 repeticiones); `claude plugin eval` solo para disparo de skills y Δ | Alternativa descartada: usar solo `plugin eval` | Confianza: media.
- Decisión: tokens y costo por JSON de `-p` más OTel; permisos por hook `PermissionRequest` y `permission_denials` | Alternativa descartada: parsear transcripciones | Confianza: media.
- Decisión: rúbrica humana de 10 ítems (0–2) y `benchmarks.lock`; protocolo completo en `_14-anexo-protocolo.md` | Alternativa descartada: juez LLM como calificador principal | Confianza: media.

## Riesgos y provisional
- Texto de FAIR4RS no verificado (solo sus identificadores F1–F2) **[provisional]**.
- Presencia de `PermissionRequest` en corridas `-p` sin humano: verificar en Fase 3 **[provisional]**.
- Número de evaluadores humanos y umbrales de aceptación **[provisional]**; Ronda 2 depende de ENDES.

## Fuentes nuevas
- https://code.claude.com/docs/en/agent-sdk/cost-tracking — contabilidad de costo citada por `headless`.
- https://zenodo.org/records/6623556 — texto oficial FAIR4RS para cerrar la rúbrica.
