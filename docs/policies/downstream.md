---
titulo: Contrato aguas abajo
estado: borrador
fecha: 2026-10-16
fase_aplicacion: F3
fuentes: [docs/research/19-contrato-aguas-abajo.md, docs/research/_19-anexo-contrato.md, docs/research/10-contrato-manifiesto-pipelines.md, docs/research/_10-anexo-manifiesto.md, docs/research/09-anotaciones-causales.md, docs/research/_09-anexo-variable-usage.md, docs/research/08-harmonizacion-y-procedencia.md, docs/adr/0002-arquitectura-hibrida.md]
---
# Política: Contrato aguas abajo

## Propósito
Definir qué expone un repo de fuente y cómo lo consumen los repos de protocolo, preparación de insumos y análisis sin descargar ni harmonizar de nuevo. Garantiza que cada cifra publicada se rastree a una versión de mart, un `cdm.lock` y un hash, y que los hallazgos vuelvan al `cdm` por PR.

## Reglas
R1. Cada repo de fuente expone `marts/` en Parquet versionados con semver de la fuente y `custom_metadata` de Arrow (versión de contrato y `cdm.lock`) — **Por qué:** el consumidor cita una versión concreta, no un DOI genérico — **Se verifica con:** validación del contrato por capa (`pointblank`/`pandera`) en CI de la fuente.
R2. `datapackage.json` lista un recurso por mart con `path`, `bytes` y `hash` `sha256:...` — **Por qué:** Frictionless admite el prefijo de algoritmo pero no define cómo verificar — **Se verifica con:** test que recalcula sha256 de cada recurso y compara.
R3. `cdm.lock` de la fuente fija la versión del `cdm` con que se construyó y, si aplica, `vocabulary_version` — **Por qué:** análogo a `CDM_SOURCE` de OHDSI; sin él no se reproduce la harmonización — **Se verifica con:** CI que falla si falta o no resuelve a un release del `cdm`.
R4. Los cargadores `tq_load(source, mart, version)` (R) y `tq.load()` (Python) descargan, comparan el hash y abortan si no coincide; escriben el hash verificado en `data.lock` del consumidor — **Por qué:** una discrepancia silenciosa invalida el análisis — **Se verifica con:** test con mart alterado que espera aborto.
R5. Cada fuente publica `CITATION.cff`, plantilla de citación (DOI del release, versión, fecha de acceso, licencia) y explorador de metadatos Quarto (diccionario, procedencia, `variable_usage`, erratas) — **Por qué:** la cita y la procedencia viajan con el dato — **Se verifica con:** `quarto render` y validación de `CITATION.cff` en CI.
R6. `ERRATA.md` y `CHANGELOG.md` acompañan cada release; una corrección solo sale en un release nuevo, nunca editando uno publicado — **Por qué:** como la página de revisiones de IPUMS, el consumidor ve qué cambió y desde cuándo — **Se verifica con:** CI que rechaza cambios a marts de un tag existente.
R7. El repo consumidor se crea desde la plantilla con `tools/bootstrap.py --mode consumer`: sin `download/`, `standardize/` ni `harmonize/`; contiene `cdm.lock`, `data.lock`, lock de dependencias (`renv.lock` o `pyproject`+lock) y `analysis/` — **Por qué:** una sola ruta de datos, la verificada — **Se verifica con:** `tests/test_consumer_mode.sh` [propuesta].
R8. Cada corrida del consumidor escribe `reports/manifest-<run_id>.json` (ADR 0011) con insumos (`path`, `layer`, `sha256`, `contract_version`), versión de código y de `cdm`, parámetros y validación — **Por qué:** el manifiesto de corrida es la evidencia de reproducibilidad — **Se verifica con:** validador del manifiesto de corrida (Fase 3, [propuesta]; `tools/make_manifest.py` solo escribe manifiestos de `raw/`) y CI que exige el manifiesto.
R9. El consumidor devuelve por PR al `cdm`: `variable_usage`, variables candidatas con procedencia (fuente, versión, código de derivación, hash) y hallazgos de calidad con evidencia reproducible; el registro es único, en el `cdm` — **Por qué:** evita registros paralelos por fuente — **Se verifica con:** plantilla de PR y validadores del `cdm`.
R10. `variable_usage(study_id, variable_id, role, estimand, dag_ref, dag_node, dag_sha256, notes, citation_doi)` con clave `(study_id, variable_id, role, estimand)` (ADR 0009) guarda el rol causal por estudio, con el DAG en `.dagitty` versionado en el repo del estudio; la tabla global `variable` no tiene columna de rol — **Por qué:** el rol depende del estudio y no debe filtrarse al registro global — **Se verifica con:** test que falla si `variable` contiene una columna `role`.
R11. Prohibido modificar marts (ni a mano ni en caliente): son de solo lectura y verificados por hash — **Por qué:** cualquier edición rompe la cadena de integridad — **Se verifica con:** cargador (R4) y CI del consumidor que compara hashes de `data.lock`.
R12. Prohibido re-derivar variables sin registrarlas en el `variable_registry` con su procedencia (`derived_from`, `rule` con hash, `rule_version`, `generated_by`, `generated_at`; ADR 0009) — **Por qué:** una derivación no registrada no es auditable ni reutilizable — **Se verifica con:** validador del `cdm` que cruza columnas derivadas del manifiesto con el registro [propuesta].
R13. Prohibido saltarse `cdm.lock`: se actualiza solo con un PR que muestre el diff (al estilo `nf-core modules update --preview`, ADR 0013) y repita la corrida del manifiesto — **Por qué:** un cambio de `cdm` altera resultados y debe quedar visible — **Se verifica con:** CI que compara `cdm.lock` contra el diff aprobado.
R15. Por nivel de congelamiento (ADR 0010, 0014): nivel 1–2 expone marts con DOI de datos; **nivel 3 expone solo agregados y salidas transformadas** (sin filas) y un consumidor que necesite microdatos los reconstruye localmente con la receta del registry (excepción explícita a R7: ese consumidor sí ejecuta la descarga oficial) y los fija en `data.lock` por sha256 sin DOI — **Por qué:** un consumidor de microdatos ENDES no tiene otra vía legal — **Se verifica con:** `audit-license` antes de release; test de que `datapackage.json` de nivel 3 no contiene recursos fila-nivel [propuesta].
R14. Los bytes de ENDES no se redistribuyen (nivel 3: receta + hash): ni `raw/` ni datos fila-nivel salen a git, DOI ni sitio, y los informes usan las plantillas de la sección Plantillas — **Por qué:** licencia y política ANDA del INEI — **Se verifica con:** `.gitignore`/CI que bloquea `raw/` y revisión de la sección de datos en el PR.

## Qué hace el agente y qué no
- Hace: crear consumidores en modo consumidor; cargar marts solo con `tq_load()`/`tq.load()`; registrar cada variable derivada y su uso; abrir PR al `cdm` con `variable_usage`, candidatas y hallazgos de calidad; rellenar las plantillas con DOI, versión y hash reales.
- No hace: modificar marts, re-derivar sin registrar, cambiar `cdm.lock` sin PR con diff; descargar o harmonizar dentro de un consumidor; redistribuir datos con restricción de licencia ni publicar fila-nivel desde `raw/`.

## Mecanismos que la hacen cumplir (Fase 3)
| Mecanismo | Tipo (hook/test/CI/skill) | Evento o disparador | Estado |
|---|---|---|---|
| `tq_load()` / `tq.load()` con aborto por hash | skill | cada carga de mart | por implementar |
| Test de sha256 contra `datapackage.json` | test | CI de la fuente y del consumidor | por implementar |
| `tools/bootstrap.py --mode consumer` y su test | skill | creación de repo consumidor | por implementar |
| Guardia de `cdm.lock` (PR con diff y rerrun del manifiesto) | CI | PR que toque `cdm.lock` | por implementar |
| Test "`variable` no contiene rol" | test | CI del `cdm` | por implementar |
| Validador de procedencia (derivadas del manifiesto vs `variable_registry`) | CI | PR del consumidor | por implementar |
| Comprobador de plantilla Métodos/Disponibilidad en el informe | test | CI del estudio | por implementar |
| Bloqueo de `raw/` y datos fila-nivel en commits | hook | `PreToolUse` y CI | por implementar |

## Provisional
- Versión de dataset en el cliente `dataverse`, error-reporting de IPUMS y alcance agregado de Strategus sin confirmar; cierra la Fase 2.
- Esquema de `manifest.json` y mapeo de procedencia (PROV-O/DataCite) son propuestas propias; se validan con una variable ENDES real en la Fase 2.
- Taxonomía de roles de `variable_usage` es propia [no oficial]; se valida con un estudio piloto en la Fase 2.
- R2 vía `endpoint` de `targets` y `dvc repro` en Windows sin probar; Fase 2.

## Fuentes
- docs/research/19-contrato-aguas-abajo.md y `_19-anexo-contrato.md`; docs/research/10-contrato-manifiesto-pipelines.md y `_10-anexo-manifiesto.md`; docs/research/09-anotaciones-causales.md y `_09-anexo-variable-usage.md`; docs/research/08-harmonizacion-y-procedencia.md; docs/adr/0002-arquitectura-hibrida.md.
- https://usa.ipums.org/usa/terms.shtml y https://usa.ipums.org/usa/revisions.shtml (2026-10-16)
- https://ohdsi.github.io/CommonDataModel/cdm54.html y https://ohdsi.github.io/Strategus/articles/IntroductionToStrategus.html (2026-10-16)
- https://nf-co.re/docs/nf-core-tools/cli/modules/update (2026-10-16)
- https://datapackage.org/standard/data-resource/ y https://datapackage.org/standard/table-schema/ (2026-10-16)
- https://pins.rstudio.com/articles/pins.html (2026-10-16)
- https://github.com/horaciochacon/dismodlite y https://docs.ropensci.org/targets/reference/tar_meta.html (2026-10-16)
- https://cran.r-project.org/web/packages/dagitty/dagitty.pdf (2026-10-16)

## Plantillas
**Métodos (pegar):**
> Los datos provienen de {fuente: p. ej. ENDES, INEI}, versión {vX.Y.Z} de los marts derivados ({DOI {doi} si nivel 1–2 | agregados sin DOI de datos y microdatos reconstruidos localmente con la receta del registry, sha256 {hash}, si nivel 3}), obtenidos mediante tinkuy-qhali {template.lock} con el modelo común de datos {cdm.lock}. Los microdatos originales se obtuvieron del sitio oficial; el repositorio conserva la receta y el hash SHA-256 de cada archivo ({hash corto}), no los bytes. La integridad se verificó con `tq_load()`. Las variables derivadas están registradas en el `variable_registry` ({ids}) y su uso en este estudio en `variable_usage` ({study_id}). El análisis se ejecutó con {R/Python versión}, dependencias fijadas en `renv.lock`, y el manifiesto de corrida {hash} se archiva en {DOI}.

**Disponibilidad de datos (pegar):**
> Los microdatos de {fuente: p. ej. ENDES} están disponibles en {enlace oficial del INEI} bajo {licencia o condiciones}; no los redistribuimos (nivel 3: receta + hash). El repositorio {repo}, DOI {doi}, contiene la receta de obtención, los punteros con SHA-256, el diccionario y el código para reconstruir los marts (v{X.Y.Z}). El código y los manifiestos de este estudio están en {repo del estudio}, DOI {doi}. Cite: {texto de CITATION.cff}.
