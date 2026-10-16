# ADR 0013 — Versionado de datos, DOI, archivos `lock` entre repos y regla capítulo vs repo

- **Estado:** aceptado
- **Fecha:** 2026-10-16
- **Complementa:** ADR 0002 (arquitectura híbrida) y ADR 0005 (nombre)
- **Fuente:** Fase 1, informes 07, 13 (+ anexo convenciones), 15 (+ anexo venues), 17, 19 (+ anexo contrato), 21, 26

## Contexto

El ADR 0002 fijó tres repos núcleo, repos por fuente bajo criterios y estudios como capítulos, pero dejó para la Fase 2 el costo de los contratos entre repos y la regla para abrir uno nuevo. La investigación encontró los patrones que lo resuelven en otros ecosistemas: `cdm_source.vocabulary_version` en OHDSI, `modules.json` con `git_sha` y `nf-core modules update --sha --preview` en nf-core, `pin_versions()` en `pins`, y el DOI de concepto frente al DOI de versión en Zenodo (informes 07 y 19). También detectó dos convenciones en conflicto para archivar bitácoras (informes 13 y 17) que este ADR unifica.

## Alternativas

- **Un repo por estudio (modelo `ohdsi-studies`):** descartado para un equipo de una persona; los estudios son capítulos salvo que cumplan un criterio de la decisión 6.
- **Versionar los marts solo por fecha:** descartado; no distingue cambio de esquema de corrección de datos.
- **Dependencias entre repos por rama o `main`:** descartado; todo consumo se fija por versión y hash.

## Decisión

1. **Semver de datos** para cada mart, diccionario y vocabulario: `MAJOR` cambia el esquema (Table Schema incompatible), `MINOR` añade una edición o variables compatibles, `PATCH` corrige datos sin cambiar esquema. El `cdm` versiona igual; su `CHANGELOG.md` es obligatorio para cualquier cambio de contrato.
2. **DOI:** cada repo núcleo y cada repo de fuente tiene un DOI de concepto en Zenodo (vía releases de GitHub) y un DOI por versión; se cita siempre el de versión y se menciona el de concepto. El código y los datos reciben DOI **separados** (informe 26): el repo de fuente publica el código con su DOI y los marts de nivel 1–2 como depósito de datos propio. Los DOI de Sandbox (10.5072) nunca se citan.
3. **Tres archivos `lock`:**
   - `cdm.lock` en todo repo que consume el `cdm`: versión semver del `cdm`, `git_sha`, versión de los vocabularios y sha256 de los Table Schema usados. Se actualiza solo por PR con diff (patrón `modules update --preview`).
   - `data.lock` en todo repo consumidor: por cada mart consumido, versión, DOI, sha256 y URL de resolución; los cargadores `tq_load()` (R) y `tq.load()` (Python) abortan si el hash no coincide.
   - `template.lock` en todo repo creado desde la plantilla: versión y `git_sha` de la plantilla, lista de skills y hooks heredados con sus hashes (`skills-registry.md`), modo (`source` o `consumer`). La skill `sync-template` propone el diff al actualizarlo.
4. **Nomenclatura** (informe 13): archivos y carpetas en `kebab-case` ASCII; fechas `AAAA-MM-DD`; ADR `NNNN-titulo.md`; informes `NN-tema.md`; bitácoras `AAAA-MM-DD-faseX-tema.md`; ramas `tipo/tema` (tipos: `feat`, `fix`, `docs`, `rescue`, `claude`); tags `vX.Y.Z`; objetos R en `snake_case`; campos legibles por máquina en inglés `snake_case` (ADR 0009).
5. **Archivo de bitácoras** (unifica informes 13 y 17): al cerrar cada fase, los archivos de `docs/agent-log/` con más de 90 días o cuando la carpeta supere 5 MB se mueven a `docs/agent-log/archivo/AAAA/` **sin comprimir** (git ya comprime; un `.tar.gz` no se puede leer ni diffear desde el agente) y se deja `docs/agent-log/archivo/INDEX.md` con una línea por archivo. `LESSONS.md` ≤ 100 líneas con compuerta humana.
6. **Regla capítulo vs repo nuevo:** nace un repo cuando se cumple **al menos uno** de: licencia distinta, ciclo de release distinto, dominio de datos distinto, tamaño que rompe los topes de higiene (`.git` > 1 GB) o equipo distinto; licencia y ciclo pesan más que los otros tres (así separan HADES y nf-core). Si no, es un capítulo (`studies/<slug>/` o `sources/<slug>/` dentro del repo que corresponde). Abrir un repo exige un ADR corto en el repo plantilla con el criterio cumplido.
7. **Modo consumidor** de la plantilla (`tools/bootstrap.py --mode consumer`, Fase 3): sin capa de descarga ni harmonización; trae `cdm.lock`, `data.lock`, cargadores, plantilla de citación y las plantillas de Métodos y Disponibilidad de datos de `docs/policies/downstream.md`; devuelve al `cdm` por PR `variable_usage`, variables candidatas con procedencia y hallazgos de calidad; nunca modifica marts ni re-deriva sin registrar.

## Consecuencias

- `CITATION.cff` y `codemeta.json` declaran el DOI de concepto del código; cada release añade el DOI de versión.
- `docs/policies/hygiene.md` y `context.md` se alinean a la decisión 5 (ruta `archivo/AAAA/`, sin `.tar.gz`).
- La Fase 3 implementa `cdm.lock`, `data.lock`, `template.lock` con sus validadores y la skill `sync-template`.
- **Provisional:** umbrales de 90 días, 5 MB y 1 GB (informes 13 y 17), se recalibran tras la Ronda 1; el paper del ecosistema apunta a JOSS y exige ≥ 6 meses de historial público, CI y release en Zenodo (informe 15).
