# 00 — Informe de investigación de la Fase 1

- **Fecha:** 2026-10-16
- **Autor:** Claude Code (consolidación) a partir de 26 informes de subagentes; decisiones del usuario Percy Soto-Becerra pendientes donde se indica.
- **Insumos:** `docs/research/01-*.md` … `26-*.md` y sus anexos `_NN-anexo-*.md`; `benchmarks/results.md`.
- **Validación:** `python tools/check_research.py` (26/26 informes válidos; test `tests/test_check_research.sh` 13/13).
- **Regla de lectura:** cada decisión conserva la confianza que le dio su informe. "Provisional" significa que la Fase indicada debe cerrarla con una prueba o una fuente.

## Resumen en cinco líneas

1. El CDM propio por capas con diseño muestral en columnas se confirma; OMOP queda como formato de vocabularios y como destino futuro de la capa clínica (v5.4), no como núcleo.
2. ENDES no es espejable en público: la política ANDA del INEI exige consentimiento escrito para copias multiusuario; queda en nivel 3 (receta + hash) y el manifiesto debe corregirse.
3. La configuración de Claude Code tenía tres errores (ADR 0008); la frontera de seguridad real en Windows es el hook `PreToolUse` y el contenedor, no las reglas de permisos.
4. `targets` orquesta; Python y Julia corren como procesos con Parquet; el benchmark del ítem 22 decide dónde entra Julia (ver fila 22).
5. Ronda 1 sin meta-aprendedor ni routines: compuerta humana manual al cierre de cada fase; Ronda 2 automatiza con holdout y reversión.

## Tabla de decisiones

| Ítem | Tema | Decisión | Confianza | Provisional / cierra en |
|---|---|---|---|---|
| 1 | Config Claude Code | Superseder ADR 0001 → ADR 0008: `ask` sí actúa en bypass; reglas `PowerShell(...)` espejo; hook `PreToolUse`; `worktree.baseRef: head` (aplicado) | alta | patrones PowerShell sin test → F3 |
| 2 | Prompting y políticas | Tres políticas: anti-sesgo (hipótesis a contrastar, "no sé", cita o [provisional], revisor en contexto fresco), anti-deriva (criterio de salida, resumen por fase, `/clear` tras dos fallos), ahorro de tokens (CLAUDE.md mínimo, scripts que resumen, lectura por rangos) | media/alta | sycofancia sin fuente oficial |
| 3 | Modelos de datos | Confirmar CDM propio por capas; corregir ADR 0003 punto 3: ids locales solo en `source_concept_id`, jerarquías locales en `concept_relationship`; OMOP v5.4 para clínica futura; matriz capa × estándar (DDI-Codebook 2.6 operativo, DDI-CDI 1.0 integración) | alta/media | licencias SDMX/CF/OGC, UBIGEO INEI–RENIEC → F2 |
| 4 | Diccionarios | YAML por variable con subconjunto de Table Schema + extensiones `x_role`, `x_universe`, `x_derivation`; `.sav` fuente primaria, PDF solo contraste; DDI y Croissant como exportación | media | generador Markdown y export → F2 |
| 5 | Licencias y derecho | Espejo público solo de CHIRPS, GDELT, ERA5 y datasets ODC-By; ENDES y ACLED receta + hash salvo autorización escrita; todo espejo declara origen, fecha, sha256, términos vigentes, licencia, no afiliación, atribución y contacto de retiro | media/alta | normas leídas en copias; revisión legal → F2 |
| 6 | Congelamiento | Cinco reglas en orden (R1 términos restrictivos → 3/4; R2 abierta+riesgo alto → 1 con recorte; R3 datos personales → 4; R4 abierta+riesgo bajo → 1 si <10 GB; R5 nivel 2 solo con autorización); 22 fuentes: 5 en nivel 1, 0 en 2, 15 en 3, 2 en 4; ENDES nivel 3; CC-BY-4.0 solo para derivados propios | media | tamaños INEI/MEF; compatibilidad ODC-By → revisión legal F2 |
| 7 | Espejos | R2 operativo, Zenodo citable (50 GB / 100 archivos por registro), Software Heritage para código, HF gated solo si hace falta, disco frío o NAS UPN como tercera copia; resolución por sha256 con `MIRRORS.md` firmado (cosign) y script que recorre mirrors | media | Dataverse propio descartado; acuerdo de espejo → F2 |
| 8 | Procedencia | Campo `procedencia` = `derivado_de`, `regla` (ruta+hash), `version_regla`, `generado_por` (ORCID), `fecha`, `comparabilidad`; mapeo a PROV-O y DataCite; `lock` apunta a `dvc.lock`/`renv.lock` | media | validar con una variable ENDES real → F2 |
| 9 | Anotaciones causales | `variable_usage(study_id, variable_id, rol, dag_ref, dag_node, dag_sha256, estimand, notas, cita_doi)`; 13 roles enumerados; DAG como `.dagitty` versionado con hash; test que falla si `variable` contiene un rol | media/alta | taxonomía propia; STROBE → F2 |
| 10 | Contrato y manifiesto | Table Schema JSON como contrato por capa (`pointblank` en R, `pandera` en Python, versión en `custom_metadata` de Parquet); manifiesto JSON estilo `dismodlite` armado desde `tar_meta()`; `targets` orquesta y llama Python/Julia con `format="file"`; DVC solo `raw/` | media | R2 vía `endpoint` de targets → F2; `gbdtool` no existe |
| 11 | Loops y contexto | Política por fase se mantiene; `PreCompact` vuelca a bitácora y `SessionStart compact` reinyecta; Stop hook con validadores deterministas y contador en archivo (tope nativo 8); Actions con pasos deterministas, `claude-code-action` solo revisión opcional; `idleCompaction: false` | alta/media | contador en archivo → tests F3 |
| 12 | Skills y MCP | 21 herramientas: 8 con skill oficial, 2 comunitarias, 11 sin nada. Instalar tras cuarentena: `duckdb/duckdb-skills`, `posit-dev/pointblank`, `cloudflare/skills`, `docker/skills`; crear: renv, arrow, haven, srvyr, targets, Julia, DVC, pre-commit, lintr/styler, Zenodo, Mermaid | alta/media | licencias NOASSERTION; Julia sin búsqueda completa |
| 13 | Nomenclatura y bitácoras | `kebab-case` ASCII, fechas ISO; ADR `NNNN-titulo`, informes `NN-tema`, bitácoras `AAAA-MM-DD-faseX-tema`; rotación al cerrar fase o >300 líneas, archivo a 90 días; `LESSONS.md` ≤100 líneas con compuerta humana; meta-aprendedor en Ronda 2 | alta/media | umbrales estimados |
| 14 | Benchmark | Arnés propio con `claude -p` y graders por script ocultos; 9 tareas B01–B09 × 3 repeticiones; `plugin eval` solo para disparo de skills; tokens por JSON de `-p` + OTel; permisos por hook `PermissionRequest`; rúbrica humana 10 ítems (0–2); `benchmarks.lock` | media | `PermissionRequest` en `-p` → F3 |
| 15 | Paper y crecimiento | Ecosistema → JOSS (falta ≥6 meses de historial, CI, release Zenodo); data paper ENDES → Scientific Data (falta DOI del dataset); nace repo si cumple ≥1 criterio (licencia y ciclo pesan más), si no es capítulo | media/baja | tarifas y plazos → F4 |
| 16 | Mermaid ISO 5807 | `@{ shape }` (Mermaid ≥ 11.3.0) + `classDef`; 10 de 11 símbolos exactos; conector fuera de página como `circle` etiquetado; fijar versión mínima en `docs/style/mermaid-iso5807.md` | media/alta | versión de Mermaid en Quarto 1.10 y GitHub → F2 |
| 17 | Higiene | Worktrees limpios se borran al cierre; sucios → rama `rescue/AAAA-MM-DD` (30 días); `git gc --auto` por sesión; topes `.git` ≤1 GB, `agent-log` ≤5 MB; pre-release busca blobs grandes | media/baja | topes sin medir |
| 18 | Seguridad | Capas: deny `curl`/`wget`; WebFetch solo dominios de `tools/allowed-domains.txt`; hook `PreToolUse` con `onFailure: block` contra push a remotos no declarados y hosts fuera de lista; Claude Code en contenedor/WSL2 con sandbox; `quarantine/` con sha256 del árbol completo y `sha` fijado; bitácora → memoria solo por PR humano | media | patrón de memoria → inyecciones sembradas F3 |
| 19 | Contrato aguas abajo | Repo de fuente expone marts Parquet, `cdm.lock`, `datapackage.json` con sha256, cargadores que abortan si el hash falla, `CITATION.cff`, explorador, `ERRATA.md`; repo consumidor lleva `cdm.lock` + `data.lock` y devuelve por PR `variable_usage`, variables candidatas y hallazgos de calidad; prohibido modificar marts, re-derivar sin registrar, saltarse `cdm.lock` | media/alta | alcance agregado de Strategus → F2 |
| 20 | Manuales | Un `manual.qmd` con perfiles Quarto `code|cowork`; Cowork carga skills/plugins desde la cuenta, no desde el repo; hooks del repo no garantizados en Cowork y el manual lo declara | media | soporte de CLAUDE.md/rules en Cowork → prueba F3 |
| 21 | Auto-mejora | Ciclo disparador → evidencia → propuesta → compuerta → medición → aceptación/reversión; un cambio por ciclo; PR con revisor humano; holdout B07–B09 oculto; cierre automático si Δ empeora; Ronda 1 manual (`reflect` + `LESSONS.md`), Ronda 2 routine | media | umbral de Δ → medir varianza F3 |
| 22 | Código R y pipelines híbridos | Benchmark ejecutado en el contenedor (186 filas, 31 implementaciones, 0 fallas, 0 no equivalentes; `benchmarks/results.md`). Join ponderado ENDES 3,4 M filas: polars 0,19 s, DuckDB 0,39–0,51, arrow 0,43, data.table 1,05, dplyr 1,69; microsimulación 1e6: Julia multihilo 0,06, Julia bucle 0,21, pyarrow 0,28, Rcpp 0,33, R vectorizado 0,74. Escalera: dplyr → arrow/DuckDB perezoso → Rcpp encapsulado con test de equivalencia; Julia solo para simulación multihilo (compila 6–9 s por proceso y pierde 4× frente a polars en joins); etapas Python/Julia como targets `format="file"` con Parquet; declarar `data.table` (ya presente como dependencia indirecta) sin usarlo por defecto | media | numpy, duckplyr, profvis ausentes en la imagen; `uv run` exige `--no-sync`; host con otros procesos (<1,5× no concluyente) |
| 23 | `r-package-scout` | Skill de 5 pasos (DESCRIPTION/licencia → mantenimiento → vignette + `Rd2txt` de 3–5 funciones → ejemplo en contenedor → `docs/packages/<pkg>.md`); APIs probadas: CRAN, crandb, cranlogs, r-universe, GitHub; no instalar `cran_mcp`; evaluar `mcptools`/`btw` tras cuarentena | media | eval de 3 casos sin ejecutar → F2 |
| 24 | Pipeline a un clic | `run.sh`/`run.bat` → `docker compose run --rm -T pipeline Rscript -e 'targets::tar_make()'` → `tar_quarto()` escribe `reports/index.html`; verifica Docker, `.env`, imagen y `dvc pull`; códigos 10–13/20/21; prueba local en `.tq-tmp/` y CI con datos sintéticos y `claude` fuera del PATH | media | código de salida de `tar_make` → F2 |
| 25 | Cunningham | Adoptar código ejecutable junto al texto y "devil's advocate" como revisores por rol; no atribuirle "documentar antes de codificar" ni la revisión por roles (sin URL pública); no adoptar paywall | alta/media | posts de IA tras paywall → F2 |
| 26 | Lo que falta | 11 temas: Ronda 1 = `rig` + guía `renv::restore()`, CONTRIBUTING/SECURITY/CODEOWNERS/CODE_OF_CONDUCT, pre-commit con gitleaks, campos `model`/`claude_code_version`/`skills_hash`/`cost_usd` en el manifiesto, `docs/ops/dr.md` (RPO 7 d, RTO 48 h), DOI de código separado del de datos, revisar licencia de `anthropics/skills` (docx/pdf/xlsx son source-available); Ronda 2 = `pointblank` en `standardized/`, axe y alt-text en CI, SBOM `syft`, REUSE, GOVERNANCE.md; nunca = README bilingüe, i18n de validadores | media/alta | RPO/RTO propuestos; REUSE y `syft` para R/Julia sin verificar |

## Correcciones a ADR previos que salen de la Fase 1

| ADR | Qué cambia | Informe | Acción |
|---|---|---|---|
| 0001 | `ask` sí actúa en bypass; reglas PowerShell; sin sandbox en Windows | 01, 11, 18 | ADR 0008 aceptado y aplicado el 2026-10-16 |
| 0003 | Conceptos locales nunca son estándar en OHDSI; van en `source_concept_id`; jerarquías en `concept_relationship`; OMOP v5.4 para clínica | 03 | ADR 0009 (Fase 2, aceptado) |
| 0004 | CC-BY-4.0 solo para derivados propios; bases derivadas de ODC-By siguen en ODC-By; de ENDES/ACLED solo salidas transformadas | 05, 06 | ADR 0010 (Fase 2, aceptado; revisión legal antes de la primera release) |
| 0007 / manifiesto ENDES | `terms_url` apunta a la política ANDA; `freeze_level` = 3 confirmado | 05, 06 | manifiesto y puntero corregidos el 2026-10-16; el usuario decidió no pedir consentimiento por ahora |

## Las cinco preguntas de la Fase 1

**1. ¿Un solo modelo de datos (por capas, conservando diseño muestral)?** Sí. Un CDM propio en cuatro capas (`raw` → `standardized` → `harmonized` → `marts`) con peso, estrato y PSU como columnas de primera clase en `harmonized`. OMOP no sirve de núcleo: `survey_conduct` solo existe en la v6.0 no soportada y no tiene campos de diseño muestral; los proyectos que cargaron encuestas perdieron pesos o usaron conceptos propios (informe 03). Se toma de OHDSI el formato de vocabularios (`concept`, `concept_relationship`, `vocabulary`) con la corrección de que los ids locales ≥ 2.000.000.000 van siempre en `source_concept_id`. La capa de encuesta se documenta en DDI-Codebook 2.6 y la integración en DDI-CDI 1.0; cada capa tiene su estándar en la matriz del anexo 03.

**2. ¿Monorepo o multirepo?** Híbrido, como votó el ADR 0002, y la Fase 1 lo refuerza: tres repos núcleo (plantilla, `cdm`, `registry`), repos por fuente solo cuando cumplen un criterio, estudios como capítulos. El costo de contratos entre repos se paga con dos archivos: `cdm.lock` (versión del CDM y de los vocabularios que consume cada repo, análogo a `cdm_source.vocabulary_version` de OHDSI y a `modules.json` de nf-core) y `data.lock` (versión y sha256 de los marts consumidos). Las actualizaciones de `cdm.lock` entran por PR con diff, nunca a mano (informes 10 y 19).

**3. ¿R o Python principal y cómo accede el otro?** R es el principal: `targets` orquesta, `renv` fija versiones, `srvyr`/`survey` llevan el diseño muestral. Python (`uv`) y Julia corren como procesos independientes que `targets` invoca con `format = "file"`; el único contrato de intercambio es Parquet con esquema validado (`custom_metadata` con la versión del contrato). `reticulate` y `JuliaCall` quedan para llamadas pequeñas e interactivas, nunca para trabajo pesado. El reparto por tipo de tarea (wrangling en DuckDB/arrow desde R, inferencia con diseño en R, ML en Python, simulación en Julia) se confirma o corrige con los números del ítem 22 (ver fila 22 y `benchmarks/results.md`).

**4. ¿Cuándo se abre otro repo?** Cuando se cumple al menos uno de: licencia distinta, ciclo de release distinto, dominio distinto, tamaño que rompe los topes de higiene, o equipo distinto; licencia y ciclo pesan más que los otros tres (así separan HADES y nf-core). Si no se cumple ninguno, es un capítulo dentro del repo que corresponde. Se descarta el modelo "un repo por estudio" de `ohdsi-studies` para un equipo de una persona (informe 15). La regla se codifica en la skill `decide-freeze-level`/`sync-template` de la Fase 3 y exige ADR al abrir cada repo.

**5. ¿Qué es esto en términos conocidos?** Un *research compendium* agéntico que funciona como *GitHub template*: compendio porque empaqueta datos (por hash, fuera de git), código, entorno (imagen con tres lockfiles) y documentación con un solo comando de ejecución (`run.sh`, informe 24); *data package* porque cada mart se publica con `datapackage.json`, sha256 y DOI (Frictionless + Zenodo, informes 07 y 19); plantilla agéntica porque codifica políticas (permisos, hooks, skills, cuarentena, benchmark con holdout) para que Claude Code opere con poco contexto y sin residuos (informes 01, 11, 17, 18, 21). No es un dataset ni un paquete R: el producto es la infraestructura de confianza.

## Decisiones que necesita el usuario antes de la Fase 2

1. ~~ADR 0008 (a)~~ — aprobado y aplicado el 2026-10-16.
2. ~~ENDES~~ — decidido el 2026-10-16: nivel 3 sin pedir consentimiento por ahora (ADR 0010).
3. **Instalaciones tras cuarentena:** autorizar la cuarentena de `duckdb-skills`, `pointblank`, `cloudflare/skills` y `docker/skills` al abrir la Fase 2 (informe 12).

## Fuentes clave que sostienen las respuestas (consultadas 2026-10-16)

- OMOP `survey_conduct` solo en v6.0, sin campos de diseño muestral: https://ohdsi.github.io/CommonDataModel/cdm60.html
- Conceptos locales ≥ 2.000.000.000 nunca estándar: https://ohdsi.github.io/CommonDataModel/customConcepts.html
- Política de acceso ENDES 2024 (ANDA INEI): http://webinei.inei.gob.pe/anda_inei/index.php/catalog/817/accesspolicy
- `ask` actúa en todo modo, `allow` no en bypass: https://code.claude.com/docs/en/permission-modes#actions-no-mode-auto-approves
- Reglas Bash no son frontera de seguridad: https://code.claude.com/docs/en/permissions#bash-rule-limits
- Base del worktree de subagentes: https://code.claude.com/docs/en/worktrees#choose-the-base-branch
- `cdm_source.vocabulary_version` como modelo de `cdm.lock`: https://ohdsi.github.io/CommonDataModel/cdm54.html#cdm_source
- `modules.json` con `git_sha` en nf-core: https://nf-co.re/docs/guidelines/pipelines/requirements/use_the_template
- `targets` con `format = "file"` y `tar_meta()`: https://docs.ropensci.org/targets/reference/tar_target.html
- Data Package / Table Schema: https://datapackage.org/standard/table-schema/

## Fuentes nuevas propuestas por los informes (bola de nieve)

52 propuestas (dos por informe) quedan listadas en la sección "Fuentes nuevas" de cada `NN-*.md`. Las que más se repiten como prioridad para la Fase 2: `OHDSI/CdmSurveySubWg` (wiki 2026), `OHDSI/GIS`, `anthropics/sandbox-runtime`, `github.com/anthropics/claude-code-action/blob/main/docs/security.md`, `ddialliance/ddi-c_2`, `w3.org/TR/prov-dm`, `ropensci/rdhs`, `r-universe.dev/docs/api`.
