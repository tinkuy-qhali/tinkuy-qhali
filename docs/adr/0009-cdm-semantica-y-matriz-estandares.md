# ADR 0009 — CDM: capa semántica corregida, entidades mínimas y matriz capa × estándar

- **Estado:** aceptado
- **Fecha:** 2026-10-16
- **Complementa:** ADR 0003 (lo precisa; no lo supersede: las decisiones 1, 2, 4 y 5 del 0003 siguen vigentes; la 3 se corrige aquí)
- **Fuente:** Fase 1, informes 03 (+ anexo matriz), 04 (+ anexo esquema), 08 (+ anexo procedencia), 09 (+ anexo `variable_usage`), 10 (+ anexo manifiesto), 22

## Contexto

El ADR 0003 adoptó el formato de vocabularios OHDSI con "vocabularios locales en el rango ≥ 2.000.000.000" sin decir dónde viven en `observation`. La investigación verificó (https://ohdsi.github.io/CommonDataModel/customConcepts.html, 2026-10-16) que en la convención OHDSI un concepto propio **nunca es estándar**: va solo en `*_source_concept_id`, necesita una relación `Maps to` hacia un concepto estándar cuando exista, y no entra en `concept_ancestor`. Además, `survey_conduct` solo existe en CDM v6.0, no soportada por las herramientas, y sin campos de peso, estrato ni PSU (https://ohdsi.github.io/CommonDataModel/cdm60.html, 2026-10-16). Perú no es miembro de SNOMED International (https://www.snomed.org/members, 2026-10-16).

Los informes 04, 08 y 09 propusieron el esquema del diccionario por variable, el campo de procedencia y la tabla `variable_usage`; el informe 10 el contrato por capa y el manifiesto por corrida. Dos informes usaron nombres de campos en idiomas distintos (08 en español, 10 en inglés) y hay que fijar uno.

## Alternativas

- **OMOP CDM completo o `survey_conduct` v6.0 como núcleo:** descartado (sin diseño muestral, v6.0 sin soporte, mapeo masivo sin retorno en Ronda 1).
- **Conceptos locales como estándar (lectura literal del ADR 0003):** descartado: rompe la convención OHDSI y bloquea la entrada futura de una fuente clínica sin re-mapear.
- **Un solo estándar para todas las capas (DDI-CDI o Frictionless):** descartado: ninguno cubre a la vez catálogo, encuesta, semántica, agregados, clima y espacial.
- **CDM propio por capas + formato OHDSI corregido + un estándar por capa:** elegido.

## Decisión

1. **`observation` lleva siempre dos columnas de concepto:** `source_concept_id` con el id local (≥ 2.000.000.000, obligatorio) y `concept_id` con el estándar OHDSI cuando exista o `0` si no. Las jerarquías locales (UBIGEO, clasificador funcional MEF, ISCO, ISCED) se expresan en `concept_relationship` (`Is a`, `Subsumes`, `Maps to`), nunca en `concept_ancestor`.
2. **Entidades mínimas de `harmonized/`:** `location` (UBIGEO canónico con tabla de equivalencias por año), `period`, `household`, `person`, `facility`, `budget_line`, `event`, `climate_cell`, y la tabla larga `observation`. **Diseño muestral como columnas de primera clase** en `household` y `person`: `weight`, `stratum`, `psu` (y `weight_type` cuando una fuente tenga varios pesos). Una tabla `design` por fuente/edición documenta el diseño (variables de peso, estratificación, conglomerados, dominios).
3. **Capa clínica futura:** OMOP CDM v5.4 (soportada por las herramientas); se re-evalúa v5.5 cuando HADES la soporte.
4. **Matriz capa × estándar** (versiones y licencias verificadas en `docs/research/_03-anexo-matriz.md`):

| Capa | Estándar operativo | Exportación / interoperabilidad |
|---|---|---|
| Catálogo y paquete | Frictionless Data Package v2 (`datapackage.json`, Table Schema) | DCAT 3 (sitio) |
| Encuesta | diccionario YAML por variable (subconjunto de Table Schema + `x_role`, `x_universe`, `x_derivation`) | DDI-Codebook 2.6; DDI-CDI 1.0 para integración |
| Semántica | tablas OHDSI `concept`, `concept_relationship`, `vocabulary` | — |
| Agregados / marts | Parquet + Table Schema | SDMX 3.1 cuando un consumidor lo exija |
| Clínico (futuro) | OMOP CDM v5.4 | HL7 FHIR R5 |
| Clima | NetCDF/CF 1.13 o Zarr v3 en `raw/`; GeoParquet en `harmonized/` | — |
| Eventos | esquemas de origen (ACLED, GDELT 2.0) en `raw/`; `event` en `harmonized/` | — |
| Espacial | GeoParquet 1.1 | OGC API Features |

5. **Vocabularios no clínicos** entran como vocabularios locales con procedencia (ISCO-08, ISCED 2011/ISCED-F 2013, UBIGEO INEI, clasificador funcional MEF, SDOH propios). SNOMED CT queda excluido salvo licencia de afiliado; LOINC y otros con licencia de redistribución entran como estándar.
6. **Diccionario por variable** (fuente única, YAML; esquema en `docs/research/_04-anexo-esquema.md`): `id`, `name`, `label`, `definition`, `domain`, `type`, `unit`, `categories`, `missingValues`, `constraints`, `x_role` (weight|stratum|psu|id|none), `x_universe`, `x_derivation`, `sources`, `concept_id`, `source_concept_id`, `provenance`, `status`, `version`. El `.sav` (etiquetas vía `haven`/`pyreadstat`) es la fuente primaria; el PDF del INEI solo contraste. Markdown, Table Schema y DDI se **generan** desde el YAML.
7. **Procedencia obligatoria** (informe 08) con nombres de campo en inglés (regla general: campos legibles por máquina en `snake_case` inglés; prosa y etiquetas en español): `derived_from` (lista de `concept_id` o `study_id` + variable + DOI/URL; PROV `wasDerivedFrom`, DataCite `IsDerivedFrom`), `rule` (ruta al código + sha256; PROV `Activity`/`used`), `rule_version` (`IsVersionOf`), `generated_by` (ORCID; `wasAttributedTo`), `generated_at` (`generatedAtTime`), `comparability` (nota estilo IPUMS), `lock` (ruta a `dvc.lock`/`renv.lock`/manifiesto de corrida).
8. **`variable_usage`** (informe 09): clave `(study_id, variable_id, role)`; campos `dag_ref`, `dag_node`, `dag_sha256`, `estimand`, `notes`, `citation_doi`; roles enumerados: `exposure, outcome, confounder, mediator, collider, instrument, effect_modifier, proxy, selection, competing_exposure, predictor, covariate_noncausal, unclassified`. El DAG es un archivo `.dagitty` versionado en el repo del estudio. **La tabla `variable` no tiene columna de rol** y ninguna vista global agrega roles; un test falla si aparece.
9. **Contrato por capa y manifiesto por corrida** (informe 10): Table Schema JSON por tabla, validado con `pointblank` (R) y `pandera` (Python); versión del contrato en `custom_metadata` de cada Parquet. Manifiesto JSON por corrida: `run_id`, `started_at`, `duration_s`, `code_version`, `cdm_version`, `container_image_digest`, `model`, `claude_code_version`, `skills_hash`, `cost_usd`, `params`, `inputs[]`/`outputs[]` ({`path`, `layer`, `sha256`, `contract_version`}), `targets[]` (de `tar_meta()`: `name`, `seconds`, `bytes`, `rss_peak_bytes`), `validation` ({`passed`, `checks[]`}). Los cuatro campos de agente vienen del informe 26; `rss_peak_bytes` del 22.

## Consecuencias

- El punto 3 del ADR 0003 se lee en adelante como lo fija la decisión 1 de este ADR.
- El repo `cdm` (Fase 3) crea `schema/` con los Table Schema, `vocabulary/` con las tres tablas OHDSI y un test que rechaza cualquier `concept_id` ≥ 2.000.000.000 en la columna `concept_id`.
- Los campos de procedencia del informe 08 se renombran al inglés al implementarlos; el anexo 08 se conserva como historia.
- **Provisional** (cierra la Fase 3 con una variable ENDES real): licencias de SDMX, CF y OGC no consignadas; tabla de equivalencias UBIGEO INEI–RENIEC; clasificador funcional MEF vigente 2026; publicación formal de DDI-Codebook 2.6.
