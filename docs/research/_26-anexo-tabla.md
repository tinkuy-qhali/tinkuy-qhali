# Anexo 26 — Tabla completa de lo que falta

Fecha: 2026-10-16. Rutas relativas al repositorio.

| Tema | Existe | Falta | Ronda | Costo/beneficio | Fuente |
|---|---|---|---|---|---|
| 1 Entorno reproducible | lockfiles `env/{r,python,julia}`; `check_renv_drift.py` en `image.yml` | `rig`/R fijo fuera del contenedor; guía de `renv::restore()` local | Ronda 1 | Bajo (README); evita falla silenciosa de versión de R | https://rstudio.github.io/renv/articles/renv.html (2026-10-16) |
| 2 Calidad de datos | Informe 10: Table Schema + pointblank (R) + pandera (Py); informe 04 sin generadores verificados | Implementación y capa de aplicación; GE descartado | Ronda 2 | Medio; se prueba con ENDES real, no en seco | https://rstudio.github.io/pointblank/ (2026-10-16) |
| 3a CONTRIBUTING/CODE_OF_CONDUCT/SECURITY/CODEOWNERS | plantillas issue/PR; sin estos archivos | los cuatro, mínimos | Ronda 1 | Bajo; necesarios para el paper (informe 15) y crecer | https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners (2026-10-16) |
| 3b pre-commit | skill propia planificada (informe 12) | `.pre-commit-config.yaml` (precommit R, gitleaks) | Ronda 1 | Bajo; frena secretos y estilo | https://lorenzwalthert.github.io/precommit/ (2026-10-16) |
| 3c GOVERNANCE.md | nada | modelo de decisión para colaboradores | Ronda 2 | Bajo; sin colaboradores aún no rinde | provisional |
| 4 Presupuesto de tokens/costo | Informe 14: `total_cost_usd`, OTel | campo `cost_usd`/tokens en manifiesto y bitácora | Ronda 1 | Bajo; datos para decidir modelo/esfuerzo | https://code.claude.com/docs/en/monitoring-usage (2026-10-16) |
| 5 Pinning modelo/skills | `benchmarks.lock` (14); hashes en skills-registry | campos `model`, `claude_code_version`, `skills_hash` en manifiesto (10) | Ronda 1 | Bajo; sin esto un re-run no es comparable | https://code.claude.com/docs/en/model-config (2026-10-16) |
| 6 Recuperación ante desastres | Informe 07 (espejos, 3-2-1 provisional) | `docs/ops/dr.md`: escenarios laptop/R2/GitHub/Zenodo, RPO 7 d, RTO 48 h (propuesta) | Ronda 1 (doc); simulacro Ronda 2 | Bajo el doc; evita pérdida de trabajo de una persona | https://about.zenodo.org/infrastructure/ (2026-10-16) |
| 7 Accesibilidad e idioma | skill `alt-text` instalada; español principal | axe en CI, alt-text en diagramas; README bilingüe | axe/alt-text Ronda 2; bilingüe nunca | Medio; cumple WCAG sin duplicar mantenimiento | https://quarto.org/docs/output-formats/html-accessibility.html (2026-10-16) |
| 8 Licencias de dependencias | `LICENSE`, `LICENSE-DATA.md`; ADR 0004 | REUSE, SBOM syft, licencias R/Py/Julia, licencia de anthropics/skills | SBOM/REUSE Ronda 2; skills Ronda 1 | Medio; skills documentales son source-available | https://github.com/anthropics/skills (2026-10-16) |
| 9 Gestión de secretos (extra) | `validate.yml` revisa secretos rastreados; informe 18 | gitleaks en pre-commit y CI; política de tokens R2/Zenodo | Ronda 1 | Bajo; tokens de R2 y Zenodo son el activo crítico | https://github.com/gitleaks/gitleaks (2026-10-16) |
| 10 DOI código vs datos (extra) | `CITATION.cff`; Zenodo Sandbox | separar concepto DOI del software y de cada versión de datos | Ronda 1 | Bajo; evita citas ambiguas en el paper | provisional |
| 11 i18n de validadores (extra) | nada | mensajes en español de pointblank | nunca | Alto esfuerzo, beneficio mínimo | provisional |

Notas: la portada de `pointblank` no menciona Arrow ni YAML; `syft` no confirma R ni Julia; `uv export --format cyclonedx1.5` está en preview.
