# Bitácora — Fase 2 (arquitectura y ADRs), estado al 2026-10-16

Volcado de estado para continuidad entre sesiones (política de contexto: por fase, no por porcentaje).

## Hecho
- Decisión del usuario: ENDES en nivel 3 (receta + hash) sin pedir consentimiento al INEI por ahora; manifest y puntero del registry corregidos (`terms_url` → política ANDA, `freeze_level_status: confirmed`) y validados contra `pointer.schema.json`.
- ADR 0008 aplicado a `~/.claude/settings.json` (respaldo `.bak-20261016-adr0008`); la regla `deny` de `curl` y la de `rm -rf` ya bloquearon comandos propios en esta sesión.
- ADR 0009 (CDM: `source_concept_id`, entidades mínimas, matriz capa × estándar, diccionario, procedencia, `variable_usage`, manifiesto), 0010 (licencias y 4 niveles de congelamiento aplicados a 22 fuentes), 0011 (pipeline `targets` + Parquet, DVC solo `raw/`, un clic), 0012 (lenguajes por tarea con el benchmark 22), 0013 (semver de datos, DOI, `cdm.lock`/`data.lock`/`template.lock`, nomenclatura, archivo de bitácoras, capítulo vs repo). `tools/check_adr.py` + `tests/test_check_adr.sh` (11/11); 14/14 ADRs válidos. ADR 0001 marcado superseded.
- Seis políticas en `docs/policies/` (context 15 reglas, hygiene 15, security 13, downstream 14, r-style 13, performance 12) y `docs/preservation/` (plan 3-2-1, carta de espejo, verificador de mirrors), redactadas por 4 subagentes a partir de los anexos de la Fase 1 y alineadas con el ADR 0013 (archivo de bitácoras en `docs/agent-log/archivo/AAAA/`, sin comprimir).
- `docs/style/mermaid-iso5807.md` (11 formas ISO con `@{ shape }`, clases, reglas) y `docs/architecture/00-flujo-agentico.md` + `01-ecosistema.md`; los tres diagramas validados con el MCP de Mermaid (`valid: true`).
- `tests/test_f2_acceptance.sh`: 41/43 antes de la revisión adversarial.

## Revisión adversarial (lote D)
- `docs/reviews/f2-adversarial.md` (opus, contexto fresco): 1 crítico, 23 mayores, 14 menores; veredicto "sí con correcciones mayores" condicionado a cerrar el crítico.
- Crítico C1 (acceso compartido a R2 podía exponer bytes de nivel 3): cerrado a nivel de diseño con el **ADR 0014** (dos remotes `r2-open`/`r2-restricted`, token de nivel 3 solo local, sin `--deep` ni `dvc pull` compartido, sin dominio público); su implementación (bucket, tokens) requiere aprobación del usuario; regla transitoria vigente.
- 20 mayores y 10 menores corregidos el mismo día (tabla de respuesta al final del informe); quedan abiertos para la Fase 3: M15 (campos nuevos del manifiesto y esquema del registry), M20 parcial (hook sobre `git add`), M21 (fijar `sha` de plugins y revisar `pptx` en la cuarentena), m6, m11, m13.
- Reprogramado a Fase 3 (M18): render de Mermaid en Quarto/GitHub, variable ENDES real para procedencia, revisión legal, código de salida de `tar_make()`.
- `tools/check_adr.py` endurecido (15 casos de test; CI lo ejecuta) y paso de CI contra archivos de datos y blobs > 5 MB.

## Pendiente para el usuario
0. **Aprobar el ADR 0014** (aislamiento de nivel 3 en R2: crear `tinkuy-qhali-open`, token de solo lectura para CI limitado a él, renombrar el bucket actual como `r2-restricted`).
1. Autorizar la cuarentena de `duckdb-skills`, `pointblank`, `cloudflare/skills` y `docker/skills` al abrir la Fase 3 (informe 12).
2. Revisión legal humana antes de la primera release pública (ADR 0010: compatibilidad CC-BY/ODC-By, términos no localizados).
3. Borrar el volumen huérfano `tinkuy-qhali_raw` (regla `deny`; pendiente desde 0.6).
4. Push de los commits de la Fase 2 (pide confirmación).

## Siguiente
- Fase 3 (scaffold Ronda 1): `_targets.R`, `tools/bootstrap.py` (modos `source`/`consumer`), `cdm` (Table Schema, vocabularios, 5 variables reales con procedencia), `registry` (`verify_mirrors.py`), hooks de `.claude/settings.json` con un test por hook, skills de la spec, `run.sh`/`run.bat`, `.lintr` + pre-commit, 5 manuales desde `docs/manual/_source.yaml`, `docs/benchmarks/protocolo.md` + `benchmarks.lock`, mover `_bootstrap/` a `docs/archive/bootstrap/`.

## Decisiones tomadas en la marcha (no irreversibles)
- Campos legibles por máquina en inglés `snake_case`; prosa y etiquetas en español (ADR 0009, decisión 7).
- Marts fila-nivel de fuentes de nivel 3 no se publican nunca; solo agregados y salidas transformadas (ADR 0010, decisión 5).
- Bitácoras archivadas sin comprimir en `archivo/AAAA/` (ADR 0013, decisión 5).
- `check_adr.py` acepta `## Votación` como sección de decisión solo por el ADR 0000.

## Incidentes y lecciones
- Las reglas `deny` del ADR 0008 bloquearon dos comandos propios (`rm -rf` de un directorio temporal, `curl` de prueba): borrar con `rm -f` + `rmdir` y descargar solo mediante scripts de `tools/`.
- `check_adr.py` comparaba el Estado en minúsculas contra un patrón con `ADR` en mayúsculas: el test sintético lo detectó antes que el repo real. Un validador nuevo necesita su test en el mismo commit.
- El resultado del MCP de Mermaid (SVG embebido, > 100 KB) supera el límite de la herramienta y se guarda en disco: leer solo el campo `valid` con Python.
- Los subagentes de redacción detectaron ocho contradicciones entre informes de la Fase 1 (idioma de campos, ruta de archivo de bitácoras, matcher del hook, NAS multiusuario vs ENDES, Parquet en Julia, cuarentena por SKILL.md vs árbol completo, dominios permitidos sin R2, `variable_usage` global); todas quedaron resueltas en ADR 0009, 0010 y 0013 o anotadas como [provisional] con fase de cierre.
