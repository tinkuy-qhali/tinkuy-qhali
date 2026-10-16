---
item: 4
titulo: Diccionarios legibles por agentes
modelo: sonnet
esfuerzo: medium
fecha: 2026-10-16
estado: borrador
---
# 04 — Diccionarios para agentes

## Pregunta
Qué estándar sirve de fuente única de verdad por variable (SPSS `.sav` + codebook PDF del INEI) para generar Markdown humano y esquemas de validación, y qué campos mínimos lleva.

## Hallazgos
- DDI-Codebook 2.6 fue aprobado por voto de miembros (anuncio 2026-04-02); es XML, y la publicación formal quedaba pendiente (https://ddialliance.org/news/ddi-codebook-version-2.6-approved-by-member-vote, 2026-10-16).
- DDI-CDI 1.0 se publicó el 2025-01-31 con codificaciones XML, JSON-LD y Turtle (https://ddialliance.org/ddi-cdi_v1.0, 2026-10-16).
- DDIwR 0.22 (CRAN, 2026-10-08) convierte entre DDI Codebook, SPSS, Stata, SAS, R y Excel, y maneja missing declarados (https://cran.r-project.org/web/packages/DDIwR/index.html, 2026-10-16).
- Table Schema (Data Package v2) ofrece `title`, `description`, `constraints` (`required`, `unique`, rangos, `pattern`, `enum`), `missingValues` con `label`, y `categories`/`categoriesOrdered` con etiquetas (https://datapackage.org/standard/table-schema/, 2026-10-16).
- Falta en Table Schema: universo, rol de diseño (peso, estrato, PSU), derivación y procedencia; deben ir como extensión propia **[provisional]**.
- Croissant es JSON-LD para datasets de ML (FileObject, RecordSet, `sha256`, versión semántica); útil para publicar, no como fuente primaria (https://docs.mlcommons.org/croissant/docs/croissant-spec.html, 2026-10-16).
- IPUMS documenta cada variable con Descripción, Comparabilidad (general y por país), Universo, Disponibilidad y Códigos (https://international.ipums.org/international-action/variables/INDGEN, 2026-10-16).
- pyreadstat expone `column_labels`, `variable_value_labels`, `variable_measure` y `missing_ranges` (con `user_missing=True`) (https://pyreadstat.readthedocs.io/en/latest/, 2026-10-16).
- haven 2.5.5 importa SPSS/Stata/SAS vía ReadStat; sjlabelled 1.2.0 manipula etiquetas y missing múltiples (https://cran.r-project.org/web/packages/haven/index.html, 2026-10-16; https://cran.r-project.org/web/packages/sjlabelled/index.html, 2026-10-16).
- DHS recodes, extracción de texto vs OCR de PDF y generadores (`frictionless` CLI, `pointblank`) no se pudieron verificar **[provisional]**.

## Decisión propuesta
- Decisión: YAML por variable, con subconjunto Table Schema (campos, `categories`, `missingValues`, `constraints`) más extensiones `x_*` (universo, rol muestral, derivación); `.sav` es fuente primaria, PDF solo contraste; DDI/Croissant se exportan después | Alternativa descartada: DDI-Codebook XML como fuente (pesado para agentes) | Confianza: media.
- Esquema mínimo en `docs/research/_04-anexo-esquema.md`.

## Riesgos y provisional
- Extensiones `x_*` no son estándar; Fase 2 debe probar el generador Markdown y la exportación a Table Schema.
- DDI-Codebook 2.6: confirmar publicación formal.

## Fuentes nuevas
- https://github.com/ddialliance/ddi-c_2 — repositorio de DDI-Codebook 2.6 con change log.
- https://dhsprogram.com/data/ — verificar estructura de los recodes DHS (no accesible hoy).
