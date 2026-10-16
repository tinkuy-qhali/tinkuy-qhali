---
item: 3
titulo: Modelos de datos, uno o varios
modelo: opus
esfuerzo: high
fecha: 2026-10-16
estado: borrador
---
# 03 — Modelos de datos: uno o varios

## Pregunta
¿Sirve OMOP CDM para encuestas con diseño complejo (pesos, estratos, PSU)? ¿Se sostiene el ADR 0003 y qué estándar va en cada capa?

## Hallazgos
- `survey_conduct` existe solo en CDM v6.0 (24 campos, ninguno de peso, estrato o PSU); v6.0 "not fully supported" por las herramientas OHDSI (https://ohdsi.github.io/CommonDataModel/cdm60.html, 2026-10-16).
- La versión actual es v5.5, sin `survey_conduct`; contenido OHDSI bajo CC BY-SA 4.0 (https://ohdsi.github.io/CommonDataModel/, 2026-10-16).
- OHDSI sugiere añadir `survey_conduct` localmente y usar v5.4 para estudios en red (https://forums.ohdsi.org/t/mapping-prom-data-to-omop-cdm-v6-0-incompatibility-with-achilles-dqd-and-cdminspection/19284, 2026-10-16).
- Pesos NHANES se guardaron en `observation` sin concepto estándar acordado; estratos y PSU, ausentes (https://forums.ohdsi.org/t/survey-weights-statistical-weights-in-cdm/414, 2026-10-16).
- El subgrupo OHDSI de encuestas (2024) prioriza instrumentos y PROMs, no diseño muestral; todo mapeo requirió conceptos propios (https://www.ohdsi.org/wp-content/uploads/2025/10/120-Gerlanc-Brief-Mapping-Survey-Data-to-OMOP-Nicole-Gerlanc.docx, 2026-10-16; https://www.ohdsi.org/wp-content/uploads/2026/03/Survey-2026.pdf, 2026-10-16).
- HDSS Nairobi en OMOP: ~60 % de ~140 variables armonizadas, pérdida de SES del hogar, sin pesos (https://www.frontiersin.org/journals/digital-health/articles/10.3389/fdgth.2025.1423621/full, 2026-10-16). No hallé cargas de DHS en OMOP.
- "OMOP is person-centric": índices de área chocan con el modelo (https://forums.ohdsi.org/t/including-deprivation-indexes-into-omop-vocabulary/18214, 2026-10-16).
- Contra el ADR: los conceptos > 2.000.000.000 son siempre no estándar, van solo en `*_source_concept_id`, requieren "Maps to" a un estándar y no entran en jerarquías (https://ohdsi.github.io/CommonDataModel/customConcepts.html, 2026-10-16).
- Perú no figura entre los 54 miembros de SNOMED International; fuera de ellos rige licencia de afiliado con posibles tarifas (https://www.snomed.org/members, 2026-10-16; https://www.snomed.org/get-snomed, 2026-10-16).

## Decisión propuesta
- Decisión: confirmar el ADR 0003 en lo esencial (CDM propio por capas, diseño muestral en columnas) | Alternativa descartada: OMOP completo o `survey_conduct` v6.0 | Confianza: alta.
- Decisión: corregir el punto 3: `observation` lleva `source_concept_id` local (≥ 2.000.000.000, siempre) y `concept_id` estándar o 0; jerarquías locales (UBIGEO, MEF) en `concept_relationship`, no en `concept_ancestor` | Alternativa descartada: conceptos locales como estándar | Confianza: media.
- Decisión: fijar CDM v5.4 para la futura capa clínica | Alternativa descartada: v5.5 sin verificar soporte | Confianza: media.
- Decisión: adoptar la matriz capa × estándar de `docs/research/_03-anexo-matriz.md` (DDI-Codebook 2.6 operativo; DDI-CDI 1.0 para integración) | Alternativa descartada: un único estándar | Confianza: media.

## Riesgos y provisional
- Licencias de SDMX, CF, OGC API, ISCO e ISCED no constan en sus páginas **[provisional]**.
- Clasificador funcional MEF vigente 2026 y tabla de equivalencias UBIGEO INEI–RENIEC sin verificar **[provisional]**; cierra Fase 2.
- Uso de DDI-Codebook por INEI **[provisional]**.

## Fuentes nuevas
- https://github.com/OHDSI/CdmSurveySubWg/wiki — guías 2026 y promoción de conceptos propios.
- https://github.com/OHDSI/GIS — vocabularios GIS/SDOH y exposiciones por lugar (clima, espacial).
