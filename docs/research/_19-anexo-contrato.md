# Anexo 19 — Contrato aguas abajo (borrador de `docs/policies/downstream.md`)

Fuentes: ver informe 19. Lo marcado [provisional] no está verificado.

## (a) Qué expone cada repo de fuente
1. `marts/` en Parquet, con versión semver de la fuente y `custom_metadata` (versión de contrato, `cdm.lock`).
2. `datapackage.json`: un recurso por mart con `path` (URL del release o registry), `bytes` y `hash` `sha256:...` (el estándar admite prefijo de algoritmo).
3. `cdm.lock`: versión del `cdm` con que se construyó, y `vocabulary_version` si aplica (análogo a `CDM_SOURCE`).
4. Funciones de carga: `tq_load(source, mart, version)` en R y `tq.load()` en Python. Descargan, comparan hash y abortan ante discrepancia; escriben el hash verificado en `data.lock` del consumidor. Se inspiran en `pin_read(version, hash)`.
5. `CITATION.cff` y plantilla de citación (DOI del release, versión, fecha de acceso, licencia).
6. Explorador de metadata (sitio Quarto): diccionario, procedencia, `variable_usage`, erratas por versión (como la página de revisiones de IPUMS).
7. `ERRATA.md` y `CHANGELOG.md` por release; correcciones solo en un nuevo release.

## (b) Repo consumidor
Se crea desde la plantilla con `tools/bootstrap.py --mode consumer`. Sin `download/`, `standardize/` ni `harmonize/`. Contiene `cdm.lock`, `data.lock`, `DESCRIPTION`/`renv.lock` (o `pyproject`+lock), `analysis/`, `manifest.json` por corrida con hashes de marts. Tipos: protocolo (solo texto y especificación de variables), preparación de datos insumo (deriva tablas analíticas **registrando** cada variable) y análisis.
Devuelve por PR al `cdm`:
- `variable_usage`: uso causal de cada variable (exposición, desenlace, confusor, mediador, colisionador, instrumento) por estudio.
- Variables candidatas con procedencia (fuente, versión, código de derivación, hash).
- Hallazgos de calidad (rangos imposibles, codificaciones inconsistentes) como issue/PR con evidencia reproducible, que la fuente corrige en un release nuevo.
Se resuelve en el repo `cdm`, no en el de fuente, para mantener un solo registro.

## (c) Prohibiciones
1. Modificar marts (ni a mano ni en caliente): son de solo lectura y verificados por hash.
2. Re-derivar variables sin registrarlas en el `variable_registry`.
3. Saltarse `cdm.lock`: actualizar solo con PR que muestre diff (como `nf-core modules update --save-diff`) y rerrun del manifiesto.
Adicionales: no redistribuir datos con restricción de licencia (como IPUMS); no publicar datos fila-nivel desde `raw/`.

## (d) Plantillas
**Métodos (pegar):** "Los datos provienen de {fuente}, versión {vX.Y.Z} (DOI {doi}), obtenidos mediante tinkuy-qhali {template.lock} con el modelo común de datos {cdm.lock}. La integridad se verificó por hash SHA-256 ({hash corto}) con `tq_load()`. Las variables derivadas están registradas en el `variable_registry` ({ids}) y su uso en este estudio en `variable_usage` ({study_id}). El análisis se ejecutó con {R/Python versión}, dependencias fijadas en `renv.lock`, y el manifiesto de corrida {hash} se archiva en {DOI}."

**Disponibilidad de datos (pegar):** "Los microdatos de {fuente} están disponibles en {enlace oficial} bajo {licencia/condiciones}; no los redistribuimos. Los marts derivados (v{X.Y.Z}), el diccionario y los punteros con SHA-256 están en {repo}, DOI {doi}. El código y los manifiestos de este estudio están en {repo del estudio}, DOI {doi}. Cite: {texto de CITATION.cff}."
