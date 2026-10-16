---
item: 19
titulo: Contrato aguas abajo
modelo: sonnet
esfuerzo: medium
fecha: 2026-10-16
estado: borrador
---
# 19 — Contrato aguas abajo

## Pregunta
Cómo resuelven IPUMS, OHDSI, nf-core y los research compendia el consumo de datos versionados, y qué contrato debe regir a los repos de protocolo, preparación y análisis de tinkuy-qhali.

## Hallazgos
- IPUMS USA: los datos de muestra no se redistribuyen salvo un subconjunto exigido por una revista y se cita según su guía (https://usa.ipums.org/usa/terms.shtml, 2026-10-16).
- IPUMS: `ipumsr` lee extractos del sistema de extracción y usa la API para pedir, descargar y consultar metadatos (https://tech.popdata.org/ipumsr/, 2026-10-16).
- IPUMS: los errores se reportan por correo o foro y se corrigen en el siguiente release, con erratas (https://usa.ipums.org/usa/revisions.shtml, 2026-10-16). **[provisional: solo vía buscador]**
- OHDSI: `CDM_SOURCE` exige `vocabulary_version` y admite `cdm_version` (https://ohdsi.github.io/CommonDataModel/cdm54.html, 2026-10-16).
- Strategus: la especificación JSON viaja a los sitios, cada módulo escribe resultados en CSV revisables antes de enviarlos, y renv aporta dependencias (https://ohdsi.github.io/Strategus/articles/IntroductionToStrategus.html, 2026-10-16). Que sean agregados no está confirmado **[provisional]**.
- nf-core: cada módulo instalado lleva un `git_sha` en `modules.json` (https://nf-co.re/docs/nf-core-tools/api_reference/4.0.2/module_lint_tests/module_version, 2026-10-16). `modules update` ofrece `--sha`, `--preview` y `--save-diff`; `.nf-core.yml` congela versiones (https://nf-co.re/docs/nf-core-tools/cli/modules/update, 2026-10-16).
- nf-core: todo módulo reporta versiones de sus herramientas (https://nf-co.re/docs/guidelines/components/modules, 2026-10-16).
- Frictionless: `path` admite URL y `hash` es MD5 por defecto o `sha1:...`; no define cómo verificar (https://datapackage.org/standard/data-resource/, 2026-10-16).
- `pins`: `pin_versions()` lista versión, fecha y hash; `pin_read()` acepta `version` (https://pins.rstudio.com/articles/pins.html, 2026-10-16).
- `rrtools`: la compendia es un paquete R; `Imports:` de DESCRIPTION lista dependencias y `renv.lock` fija versiones (https://github.com/benmarwick/rrtools, 2026-10-16; https://rstudio.github.io/renv/articles/renv.html, 2026-10-16).
- Cliente `dataverse`: se identifica por DOI y `filename` (https://cran.nics.utk.edu/cran/web/packages/dataverse/readme/README.html, 2026-10-16). Fijar versión **[provisional: argumento no verificado]**.

## Decisión propuesta
- Decisión: cada repo de fuente expone marts Parquet versionados, `cdm.lock`, `datapackage.json` con `sha256`, cargadores R/Python que abortan si el hash no coincide, plantilla de citación y explorador | Alternativa descartada: entregar solo el DOI | Confianza: media.
- Decisión: repo consumidor (protocolo, insumo, análisis) con `cdm.lock` y `data.lock` (versión y hash), sin descarga ni harmonización; devuelve por PR al `cdm` `variable_usage`, variables candidatas con procedencia y hallazgos de calidad, | Alternativa descartada: correos informales | Confianza: media.
- Decisión: prohibido modificar marts, re-derivar sin registrar y saltarse `cdm.lock`; plantillas en el anexo | Alternativa descartada: guía no vinculante | Confianza: alta.

## Riesgos y provisional
- Versión en `dataverse`, error-reporting de IPUMS y alcance agregado de Strategus sin confirmar; Fase 2.

## Fuentes nuevas
- https://ohdsi.github.io/Strategus/ — guía "Working with results" para confirmar qué se comparte.
- https://docs.ropensci.org/dataverse/reference/get_dataframe_by_name.html — confirmar si admite versión de dataset.
