# ADR 0004 — Licencias: MIT para código, CC-BY-4.0 condicionada para derivados

- **Estado:** aceptado (la aplicación por fuente depende de la Fase 1, ítems 5 y 6)
- **Fecha:** 2026-10-16

## Contexto

El ecosistema produce dos clases de artefactos: código (plantilla, validadores, skills, pipelines) y derivados de datos (diccionarios estructurados, `variable_registry`, marts, agregados). Los derivados dependen de los términos de cada fuente (INEI, MEF, SUSALUD, SENAMHI, Copernicus, ACLED, GDELT…), que no se han verificado todavía.

## Alternativas

| Opción | Pros | Contras |
|---|---|---|
| MIT + CC-BY-4.0 (elegida) | Máxima reutilización; coherente con `dismodlite` y `ENDES.PE` (MIT); atribución obligatoria favorece citas; compatible con Zenodo/Dataverse | No protege contra apropiación sin compartir mejoras |
| Apache-2.0 + CC-BY-4.0 | Cláusula de patentes | Más pesada para un proyecto académico; sin beneficio claro hoy |
| MIT + CC-BY-SA-4.0 | Copyleft en derivados | Reduce reutilización institucional y comercial; fricción con licencias de fuentes |
| MIT + CC0 | Dominio público | Sin atribución obligatoria → menos citas |

## Decisión

1. Código: **MIT** en todos los repos (`LICENSE`).
2. Derivados: **CC-BY-4.0** (`LICENSE-DATA`), **condicionada** al nivel de congelamiento asignado a cada fuente por la matriz de la Fase 1 (ítem 6): un derivado se publica bajo CC-BY-4.0 solo si los términos de la fuente permiten redistribución; si no, el nivel baja a "espejo restringido" o "receta + hash".
3. Cada mart y cada diccionario declara en su `manifest.json` la licencia efectiva y la URL de los términos de la fuente vigentes en la fecha de descarga.
4. Ante duda sobre una fuente, el nivel por defecto es "receta de descarga + hash públicos" (restricción de la especificación).

## Consecuencias

- `CITATION.cff` y `codemeta.json` declaran MIT; el sitio y el README explican la dualidad código/datos.
- El agente adversarial de pre-release incluye una comprobación de licencia por artefacto (skill `audit-license`).
