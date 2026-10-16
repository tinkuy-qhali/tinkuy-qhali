# Anexo 13 — Convenciones de nombres de tinkuy-qhali (propuesta)

Reglas generales: ASCII, minúsculas, `kebab-case`, sin espacios; `_` inicial = auxiliar excluido del validador; números con ceros a la izquierda; fechas `YYYY-MM-DD`.

| Objeto | Patrón | Ejemplo |
|---|---|---|
| ADR | `docs/adr/NNNN-titulo.md` | `0007-remote-dvc-r2.md` |
| Informe de investigación | `docs/research/NN-tema.md`; anexos `_NN-anexo-tema.md` | `13-nomenclatura-...md` |
| Bitácora | `docs/agent-log/YYYY-MM-DD-faseX-tema.md` | `2026-10-16-fase1-arranque.md` |
| Bitácora archivada | `docs/agent-log/archivo/AAAA/` + `INDEX.md` | |
| Reglas | `.claude/rules/tema.md` | `reproducibilidad.md` |
| Skills / agentes | `.claude/skills/<verbo-objeto>/SKILL.md`; `.claude/agents/<rol>.md` | |
| Ramas | `tipo/tema` (feat, fix, docs, research) | `docs/fase1-item13` |
| Tags | `vMAJOR.MINOR.PATCH`; sandbox con sufijo `-sandbox` | `v0.0.1-sandbox` |
| Datos | `raw/<fuente>-<encuesta>-<anio>-<modulo>`; `.dvc` junto al dato | `inei-endes-2024-1629` |
| Cuadernos/scripts | `NN-verbo-objeto.qmd` / `.R` | `01-limpiar-hogar.R` |
| Lecciones | `LESSONS.md` (raíz, ≤ 100 líneas, entradas fechadas) | |

Rotación: cerrar fase = archivo nuevo; archivo > 300 líneas = dividir; > 90 días = a `archivo/`. Las lecciones entran por propuesta del agente y aprobación humana; recurrencia >= 2 = regla; incumplimiento crítico = hook.
