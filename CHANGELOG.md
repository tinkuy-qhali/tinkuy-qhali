# Changelog

Formato: [Keep a Changelog](https://keepachangelog.com/es/1.1.0/); versionado semántico. Cambios en contratos, registro y políticas son obligatorios aquí.

## [Unreleased]

### Added
- Fase 1: 26 informes de investigación `docs/research/NN-*.md` con 22 anexos, consolidado `docs/research/00-informe-investigacion.md` (tabla de decisiones, correcciones a ADR 0001/0003/0004, cinco respuestas); `tools/check_research.py` + `tests/test_check_research.sh`; `tools/harvest_research.py`; `tests/test_f1_acceptance.sh`; `benchmarks/` (join/agregación ENDES y microsimulación 1e6 en R, Python y Julia; `run_all.R` → `results.parquet`); ADR 0008 (propuesto, supersede 0001); `worktree.baseRef: "head"` en `.claude/settings.json`.
- Fase 0: ADR 0000–0005 (alineación, configuración de Claude Code, arquitectura híbrida, CDM por capas, licencias, nombre), `tools/profile_machine.py`, `tests/test_f0_acceptance.sh`.
- Fase 0.6 (cierre): DVC `--no-scm` con remote Cloudflare R2, primer dato ENDES 2024 módulo 1629 (`raw/inei-endes/2024/1629/`) con manifiesto y puntero en `tinkuy-qhali-registry`; release de prueba `v0.0.1-sandbox` → DOI Sandbox 10.5072/zenodo.621101 (no citable); plugins `quarto`, `r-lib`, `document-skills` tras cuarentena (`docs/tooling/skills-registry.md`); `docs/benchmarks/baseline.md`.
- Fase 0.6: imagen única (`Dockerfile`, `compose.yaml`, `.devcontainer/`, `docker/entrypoint.sh`), `start.sh`/`start.bat`, entornos `env/{r,python,julia}`, ADR 0006, sitio Quarto (`_quarto.yml`, `index.qmd`, `MANIFESTO.md`, `docs/site/`), workflows `site`, `validate`, `image`, `mirrors-verify`, plantillas de issue/PR, `CITATION.cff`, `LICENSE`, `LICENSE-DATA.md`, `tests/test_bootstrap.sh`.
