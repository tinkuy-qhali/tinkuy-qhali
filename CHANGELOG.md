# Changelog

Formato: [Keep a Changelog](https://keepachangelog.com/es/1.1.0/); versionado semántico. Cambios en contratos, registro y políticas son obligatorios aquí.

## [Unreleased]

### Added
- Fase 2: ADR 0009 (CDM: `source_concept_id`, entidades mínimas, matriz capa × estándar, diccionario, procedencia, `variable_usage`, manifiesto), 0010 (licencias y niveles de congelamiento por fuente; ENDES nivel 3 confirmado), 0011 (pipeline `targets` + Parquet, DVC solo `raw/`, un clic), 0012 (lenguajes por tarea con benchmark), 0013 (semver de datos, DOI, `cdm.lock`/`data.lock`/`template.lock`, nomenclatura, capítulo vs repo), 0014 propuesto (aislamiento de nivel 3 en R2); `docs/policies/{context,hygiene,security,downstream,r-style,performance}.md`; `docs/preservation/`; `docs/style/mermaid-iso5807.md`; `docs/architecture/00-flujo-agentico.md` y `01-ecosistema.md` (Mermaid validado); `tools/check_adr.py` + test; `tests/test_f2_acceptance.sh`; `docs/reviews/f2-adversarial.md`.

### Changed
- Fase 2: ADR 0001 superseded por ADR 0008 (configuración de Claude Code aplicada al nivel usuario con respaldo); manifest y puntero `inei-endes-2024-1629` con `terms_url` a la política ANDA del INEI y `freeze_level_status: confirmed`.

### Added (fases previas)
- Fase 1: 26 informes de investigación `docs/research/NN-*.md` con 22 anexos, consolidado `docs/research/00-informe-investigacion.md` (tabla de decisiones, correcciones a ADR 0001/0003/0004, cinco respuestas); `tools/check_research.py` + `tests/test_check_research.sh`; `tools/harvest_research.py`; `tests/test_f1_acceptance.sh`; `benchmarks/` (join/agregación ENDES y microsimulación 1e6 en R, Python y Julia; `run_all.R` → `results.parquet`); ADR 0008 (propuesto, supersede 0001); `worktree.baseRef: "head"` en `.claude/settings.json`.
- Fase 0: ADR 0000–0005 (alineación, configuración de Claude Code, arquitectura híbrida, CDM por capas, licencias, nombre), `tools/profile_machine.py`, `tests/test_f0_acceptance.sh`.
- Fase 0.6 (cierre): DVC `--no-scm` con remote Cloudflare R2, primer dato ENDES 2024 módulo 1629 (`raw/inei-endes/2024/1629/`) con manifiesto y puntero en `tinkuy-qhali-registry`; release de prueba `v0.0.1-sandbox` → DOI Sandbox 10.5072/zenodo.621101 (no citable); plugins `quarto`, `r-lib`, `document-skills` tras cuarentena (`docs/tooling/skills-registry.md`); `docs/benchmarks/baseline.md`.
- Fase 0.6: imagen única (`Dockerfile`, `compose.yaml`, `.devcontainer/`, `docker/entrypoint.sh`), `start.sh`/`start.bat`, entornos `env/{r,python,julia}`, ADR 0006, sitio Quarto (`_quarto.yml`, `index.qmd`, `MANIFESTO.md`, `docs/site/`), workflows `site`, `validate`, `image`, `mirrors-verify`, plantillas de issue/PR, `CITATION.cff`, `LICENSE`, `LICENSE-DATA.md`, `tests/test_bootstrap.sh`.
