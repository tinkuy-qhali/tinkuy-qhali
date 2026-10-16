---
item: 26
titulo: Lo que probablemente falta
modelo: sonnet
esfuerzo: medium
fecha: 2026-10-16
estado: borrador
---
# 26 — Lo que probablemente falta

## Pregunta
Qué temas transversales no cubren los informes 01–25 (ítem 22 pendiente) y en qué ronda entran, con costo/beneficio. Tabla en `_26-anexo-tabla.md`.

## Hallazgos
- Entorno: `renv::restore()` instala las versiones del lockfile pero no R; la documentación remite a `rig`, y `tools/check_renv_drift.py` ya corre en `image.yml` (https://github.com/tinkuy-qhali/tinkuy-qhali/blob/main/tools/check_renv_drift.py, https://rstudio.github.io/renv/articles/renv.html, 2026-10-16).
- Calidad de datos: el informe 10 fija `pointblank` (R) y `pandera` (Python); `pointblank` valida tablas DuckDB y remotas, sin mención de Arrow en su portada (https://rstudio.github.io/pointblank/, https://github.com/tinkuy-qhali/tinkuy-qhali/blob/main/docs/research/10-contrato-manifiesto-pipelines.md, 2026-10-16).
- Gobernanza: no existen CONTRIBUTING, SECURITY, CODEOWNERS ni `.pre-commit-config.yaml`; sí hay plantillas y `CITATION.cff` (https://github.com/tinkuy-qhali/tinkuy-qhali/blob/main/.github/PULL_REQUEST_TEMPLATE.md, 2026-10-16). CODEOWNERS vive en `.github/`, raíz o `docs/` y pide revisión automática (https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners, 2026-10-16).
- Costo: el informe 14 captura `total_cost_usd` y OTel (`model` en cada métrica; `app.version` solo con `OTEL_METRICS_INCLUDE_VERSION=true`), pero el manifiesto del informe 10 no tiene `model`, versión de Claude Code ni hash de skills (https://code.claude.com/docs/en/monitoring-usage, https://github.com/tinkuy-qhali/tinkuy-qhali/blob/main/docs/research/_10-anexo-manifiesto.md, 2026-10-16).
- Pinning: los alias `sonnet`/`opus` cambian de versión; se fija con el nombre completo o `ANTHROPIC_DEFAULT_SONNET_MODEL` (https://code.claude.com/docs/en/model-config, 2026-10-16).
- DR: R2 declara once nueves de durabilidad y 99,9 % de disponibilidad; Zenodo guarda dos réplicas y respaldo diario; el 3-2-1 del informe 07 sigue **[provisional]** (https://developers.cloudflare.com/r2/reference/durability/, https://about.zenodo.org/infrastructure/, 2026-10-16).
- Accesibilidad: Quarto integra axe-core con objetivo WCAG (`standard: wcag21aa`) (https://quarto.org/docs/output-formats/html-accessibility.html, 2026-10-16).
- Licencias: `anthropics/skills` mezcla Apache 2.0 con skills de documentos "source-available" (docx, pdf, pptx, xlsx), justo los de `document-skills` instalados; `syft` genera CycloneDX/SPDX de imágenes, sin confirmar R ni Julia (https://github.com/anthropics/skills, https://docs.astral.sh/uv/concepts/projects/export/, https://github.com/anchore/syft, 2026-10-16).
- Secretos: `validate.yml` revisa solo que no haya datos ni secretos rastreados; `gitleaks` ofrece hook pre-commit (https://github.com/tinkuy-qhali/tinkuy-qhali/blob/main/.github/workflows/validate.yml, https://github.com/gitleaks/gitleaks, 2026-10-16).
- REUSE, `pip-licenses` y reporte privado de SECURITY.md: sin verificar **[provisional]**.

## Decisión propuesta
- Decisión: Ronda 1 = rig en README, CONTRIBUTING/SECURITY/CODEOWNERS/CODE_OF_CONDUCT mínimos, pre-commit con gitleaks, campos `model`/`claude_code_version`/`skills_hash`/`cost_usd` en el manifiesto, `docs/ops/dr.md` (RPO 7 días, RTO 48 h), separar DOI de código y de datos | Alternativa descartada: posponer | Confianza: media.
- Decisión: Ronda 2 = `pointblank` en `standardized/`, axe en CI, SBOM `syft` y REUSE | Alternativa descartada: Great Expectations | Confianza: media.
- Decisión: nunca README bilingüe ni i18n de validadores en este alcance | Alternativa descartada: traducir ahora | Confianza: alta.

## Riesgos y provisional
- RPO/RTO son propuestas sin fuente; se ensayan en Ronda 2. Licencia de `anthropics/skills`: leer por carpeta.

## Fuentes nuevas
- https://reuse.software/ — especificación REUSE a revisar antes de decidir cumplimiento de licencias.
- https://docs.sigstore.dev/cosign/signing/signing_with_blobs/ — firma de SBOM e imagen, complementa DR y procedencia.
