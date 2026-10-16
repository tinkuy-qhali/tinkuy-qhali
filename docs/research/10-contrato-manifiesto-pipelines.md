---
item: 10
titulo: Contrato, manifiesto y pipelines deterministas
modelo: sonnet
esfuerzo: medium
fecha: 2026-10-16
estado: borrador
---
# 10 — Contrato, manifiesto y pipelines deterministas

## Pregunta
Qué tomar de `dismodlite`, `targets`, DVC, Kedro, nf-core y de los esquemas de tabla para el contrato de capas, el manifiesto por corrida y la orquestación en Windows+contenedor.

## Hallazgos
- `dismodlite` define "el contrato de insumos" (config.yaml más tablas con columnas comunes); `dl_revisar_proyecto()` valida; cada corrida guarda un manifiesto con insumos, decisiones, valores por defecto y hash de insumos (https://github.com/horaciochacon/dismodlite, 2026-10-16).
- No existe `gbdtool` entre los 32 repositorios públicos de horaciochacon (https://github.com/horaciochacon?tab=repositories, 2026-10-16).
- `tar_meta()` registra por target hash de datos, de comando y de dependencias, semilla, tamaño y segundos (https://docs.ropensci.org/targets/reference/tar_meta.html, 2026-10-16). `tar_manifest()` lista comando, formato, repositorio y `deployment` (https://docs.ropensci.org/targets/reference/tar_manifest.html, 2026-10-16).
- `format = "parquet"` exige `arrow` y data frame; `"file"` rastrea archivos; `repository` admite local, aws, gcp (https://docs.ropensci.org/targets/reference/tar_target.html, 2026-10-16). `tar_resources_aws()` tiene `endpoint` para S3-compatible, lo que haría viable R2 **[provisional: sin prueba con R2]** (https://docs.ropensci.org/targets/reference/tar_resources_aws.html, 2026-10-16).
- `crew` se activa con `tar_option_set(controller = ...)`; `deployment = "main"` ejecuta en el proceso central (https://books.ropensci.org/targets/crew.html, 2026-10-16).
- `dvc.yaml` declara `cmd`, `deps`, `outs`, `params`; `dvc.lock` guarda hashes por etapa (https://doc.dvc.org/user-guide/project-structure/dvcyaml-files, 2026-10-16). `dvc exp` requiere Git (https://doc.dvc.org/command-reference/exp, 2026-10-16).
- Kedro: `DataCatalog` con `versioned: True` y `validator` opcional (https://docs.kedro.org/en/stable/catalog-data/data_catalog/, 2026-10-16).
- nf-core: `nextflow_schema.json` es JSON Schema de parámetros validado por nf-schema (https://nextflow-io.github.io/nf-schema/latest/nextflow_schema/nextflow_schema_specification/, 2026-10-16); los módulos deben reportar versiones (https://nf-co.re/docs/guidelines/components/modules, 2026-10-16).
- Table Schema: `fields`, `constraints`, `primaryKey`, `foreignKeys` (https://datapackage.org/standard/table-schema/, 2026-10-16). `pandera` valida pandas, polars, pyarrow (https://pandera.readthedocs.io/en/stable/, 2026-10-16). `pointblank` valida con `create_agent()` e `interrogate()` (https://rstudio.github.io/pointblank/, 2026-10-16). Arrow admite `custom_metadata` en esquema y campos (https://arrow.apache.org/docs/format/Columnar.html, 2026-10-16).

## Decisión propuesta
- Decisión: contrato por capa como Table Schema JSON (fuente única), con `pointblank` en R y `pandera` en Python y `custom_metadata` de Arrow con versión de contrato en cada Parquet | Alternativa descartada: Great Expectations (no revisada) | Confianza: media.
- Decisión: manifiesto por corrida JSON al estilo `dismodlite` (insumos con hash, versión de código y de `cdm`, parámetros, duración), armado desde `tar_meta()`; esquema en `_10-anexo-manifiesto.md` | Alternativa descartada: depender solo de `dvc.lock` | Confianza: media.
- Decisión: `targets` orquesta R y llama Python/Julia con `format = "file"`; DVC solo versiona `raw/`, con `--no-scm` en bind mounts | Alternativa descartada: Kedro o nf-core completos | Confianza: media.

## Riesgos y provisional
- R2 vía `endpoint` y `dvc repro` en Windows sin probar; Fase 2.
- Snakemake no se revisó; Kedro y nf-core son solo ideas.

## Fuentes nuevas
- https://docs.ropensci.org/targets/reference/tar_resources_aws.html — confirmar parámetros de `endpoint` y regiones para R2.
- https://docs.kedro.org/en/stable/hooks/introduction.html — hooks de Kedro para registrar el manifiesto (no consultada).
