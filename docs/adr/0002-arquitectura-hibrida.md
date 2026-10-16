# ADR 0002 — Arquitectura híbrida con capítulos y repos públicos

- **Estado:** aceptado
- **Fecha:** 2026-10-16
- **Votación:** agente C, usuario C (ADR 0000 §0.4)

## Contexto

La especificación imagina cinco tipos de repo (plantilla, `cdm`, `data-registry`, por fuente, por estudio) y pide evaluarlos, no asumirlos. El equipo es una persona; el benchmark de Ronda 1 debe medir valor, no coordinación entre repos.

## Alternativas consideradas

- **A. Monorepo:** descartado porque no funciona como GitHub template (clonar trae todo) y no separa DOI ni licencias por fuente.
- **B. Multirepo puro:** descartado para Ronda 1 por costo de coordinación (4–6 CI, 4 contratos, deriva entre repos) sin evidencia de necesidad.
- **C. Híbrido con capítulos:** elegido.

## Decisión

1. **Tres repos núcleo** en Ronda 1, todos públicos desde el commit 1 bajo la organización GitHub `tinkuy-qhali`:
   - `tinkuy-qhali` — plantilla (GitHub template), sitio Quarto, manifiesto, políticas, capa agéntica.
   - `tinkuy-qhali-cdm` — esquemas, vocabularios (formato OHDSI), `variable_registry`, `variable_usage`, validadores. Versionado con semver; los consumidores fijan `cdm.lock`.
   - `tinkuy-qhali-registry` — punteros a bytes crudos (DOI/URL/SHA-256), resolutor por hash, `MIRRORS.md`, verificación periódica.
2. **Repos por fuente** se generan desde la plantilla **solo si** cumplen al menos uno de los criterios para abrir repo: licencia distinta, ciclo de release distinto, dominio distinto, tamaño (> 1 GB de punteros o > 50 tablas), equipo distinto. ENDES cumple licencia y ciclo distintos → `tinkuy-qhali-endes` en Ronda 2.
3. **Estudios y fuentes pequeñas son capítulos:** carpetas `studies/<study_id>/` o `sources/<source_id>/` con su propio `manifest.json`, dentro del repo que las aloja, compartiendo `template.lock` y `cdm.lock`. La skill `add-source` incorpora la decisión capítulo-vs-repo y la registra en un ADR del repo afectado.
4. `raw/` nunca entra a git en ningún repo; por eso la visibilidad pública no expone datos.

## Consecuencias

- Ronda 1 mantiene 3 CI y 2 contratos (`cdm.lock`, formato de puntero) más `template.lock`.
- Un capítulo puede "graduarse" a repo con `tools/bootstrap.py` sin reescribir historial de datos (los punteros ya viven en `registry`).
- Riesgo aceptado: decidir mal el umbral; se revisa con las lecciones del piloto (Fase 4).
