---
item: 8
titulo: Harmonización y procedencia de variables
modelo: sonnet
esfuerzo: medium
fecha: 2026-10-16
estado: borrador
---
# 08 — Harmonización y procedencia

## Pregunta
¿Qué estructura de regla de derivación copiar de IPUMS, DHS, GBD y paquetes latinoamericanos, y qué subconjunto mínimo de PROV-O, DataCite y CITATION.cff basta para un registro YAML de variables con procedencia?

## Hallazgos
- IPUMS USA traduce a códigos uniformes, usa códigos generales más detallados y documenta universo, comparabilidad y notas por variable (https://usa.ipums.org/usa/intro.shtml, 2026-10-16).
- DHS mantiene el nombre de variable común entre fases, no reutiliza nombres de preguntas eliminadas y publica Recode Manual y Recode Map como libro de códigos (https://dhsprogram.com/pubs/pdf/DHSG4/Recode7_DHS_10Sep2018_DHSG4.pdf, 2026-10-16; vía resumen de búsqueda, no leído el PDF).
- `rdhs` extrae variables, conserva etiquetas y armoniza con `rbind_labelled()` (https://docs.ropensci.org/rdhs/, 2026-10-16).
- GBD publica jerarquías de causas con DOI y mapas causa-CIE por separado (https://ghdx.healthdata.org/record/global-burden-disease-study-2021-gbd-2021-cause-rei-and-location-hierarchies, 2026-10-16).
- PROV-O: términos de partida Entity, Activity, Agent, wasDerivedFrom, wasGeneratedBy, used, wasAttributedTo (https://www.w3.org/TR/prov-o/, 2026-10-16).
- DataCite 4.6: IsDerivedFrom (A se basa en B), IsSourceOf (inversa), IsVersionOf, Compiles (https://datacite-metadata-schema.readthedocs.io/en/4.6/appendices/appendix-1/relationType/, 2026-10-16).
- CFF 1.2.0: `references` lista obras de las que depende el dato; `preferred-citation` redirige la cita (https://raw.githubusercontent.com/citation-file-format/citation-file-format/main/schema-guide.md, 2026-10-16).
- RO-Crate: CreateAction con agent, object, result, instrument y endTime (https://www.researchobject.org/ro-crate/specification/1.2/provenance.html, 2026-10-16).
- `tar_meta()` guarda hashes de datos y comandos; `dvc.lock` guarda cmd, deps y outs con hash (https://docs.ropensci.org/targets/reference/tar_meta.html, 2026-10-16; https://doc.dvc.org/user-guide/project-structure/dvcyaml-files, 2026-10-16).
- `PNADcIBGE` solo descarga, lee y analiza; el paquete `ech` fue retirado de CRAN (https://cran.r-project.org/web/packages/PNADcIBGE/index.html, 2026-10-16; https://cran.r-project.org/web/packages/ech/index.html, 2026-10-16).
- `enaho`, `casen`, `geobr`, codemeta 3.0 y Kedro/nf-core: **[provisional]**, sin verificar.

## Decisión propuesta
- Decisión: campo `procedencia` con `derivado_de` (lista de concept_id o study_id+variable+DOI/URL; PROV `wasDerivedFrom`, DataCite `IsDerivedFrom`), `regla` (ruta al código y hash; `Activity`/`used`), `version_regla` (`IsVersionOf`), `generado_por` (ORCID; `wasAttributedTo`), `fecha` (`generatedAtTime`) y `comparabilidad` (nota estilo IPUMS). Esquema en `_08-anexo-procedencia.md` | Alternativa descartada: PROV-JSON completo por variable | Confianza: media.
- Decisión: `lock` de `dvc.lock`/`renv.lock` como evidencia de ejecución, sin duplicarla en el YAML | Alternativa descartada: RO-Crate por variable | Confianza: media.

## Riesgos y provisional
- El mapeo es una propuesta propia **[provisional]**; se valida en Fase 2 con una variable ENDES real.
- Falta leer los manuales DHS y los paquetes latinoamericanos.

## Fuentes nuevas
- https://www.w3.org/TR/prov-dm/ — modelo conceptual para fijar la semántica de derivación.
- https://github.com/ropensci/rdhs — código de `rdhs` para copiar el patrón de armonización de etiquetas.
