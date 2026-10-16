# Anexo 21 — Ciclo de auto-mejora con compuerta humana

Fecha: 2026-10-16. Este anexo es diseño propio **[provisional]**, apoyado en las fuentes del informe 21.

## Ciclo (6 pasos)
1. **Disparador.** Ronda 1: cierre de fase, a mano. Ronda 2: routine semanal, o evento `pull_request.closed`, o más de 3 cambios de política por fase (umbral del informe 13). Mínimo entre ciclos: 1 semana.
2. **Evidencia.** El proponente solo ve: bitácoras recientes, `permission_denials`, recurrencias en `LESSONS.md` y los `results` de las tareas de desarrollo (B01–B06, a decidir). No ve las tareas de retención ni sus graders.
3. **Propuesta.** Un PR en rama `claude/mejora-<tema>` con **un** cambio (una regla, un hook o una skill), la hipótesis, el Δ esperado y la regla que se retira si hay inflación (presupuesto: CLAUDE.md < 200 líneas; `LESSONS.md` <= 100).
4. **Compuerta.** Revisor humano obligatorio (CODEOWNERS + branch protection). Checklist: ¿evidencia con >= 2 recurrencias?, ¿se puede convertir en hook?, ¿contradice un ADR?, ¿se leyeron transcripciones, no solo la métrica?
5. **Medición.** GitHub Actions con pasos deterministas corre las tareas de desarrollo y las de retención, 3 repeticiones, y compara con `benchmarks.lock`: pasa/falla, pass^3, costo, `permission_denials`, residuos. Regla de aceptación: ninguna tarea de retención baja, Δ de desarrollo >= umbral, costo <= +10 %.
6. **Aceptación o reversión.** Si cumple: el humano fusiona y actualiza `benchmarks.lock` en un commit aparte. Si no: la Action comenta, etiqueta `revertido` y cierra el PR; si ya estaba fusionado, abre un PR de reversión automático. Todo ciclo (aceptado o no) deja una entrada en `docs/agent-log/`.

## Controles
| Riesgo | Control |
|---|---|
| Sobreajuste (Goodhart) | Holdout oculto; rotar 1 de 3 tareas de retención por ronda; leer transcripciones |
| Deriva de políticas | Un cambio por ciclo; ADR si toca una decisión; reversión automática |
| Inflación de reglas | Presupuesto de líneas; toda regla nueva retira otra o se vuelve hook |
| Degradación invisible | Métricas múltiples (pasa/falla, costo, permisos, residuos); suite de regresión |
| Costo de tokens | `--max-turns`, tope de 1 ciclo por semana, costo en `results` |
| Auto-aprobación | La Action no tiene permiso de fusión; el proponente no edita `benchmarks.lock` ni los graders |

## Reparto por ronda
- **Ronda 1:** revisión manual al cierre de fase, `LESSONS.md` con compuerta, Action de medición contra `benchmarks.lock`, bitácora del ciclo.
- **Ronda 2:** routine que prepara evidencia y abre el PR (rama `claude/`), holdout rotativo, reversión automática. Condición: informe 13 (meta-aprendedor solo en Ronda 2).
