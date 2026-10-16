# Registro de skills, plugins y MCP

Regla (spec Fase 1, ítem 12): oficial del fabricante > comunitario con mantenimiento activo > propio. **Nada se instala sin cuarentena**: se lee cada `SKILL.md` en la versión exacta (commit) antes de habilitarlo, se busca ejecución de shell remoto, exfiltración, secretos y frases de anulación de instrucciones, y se registra el hash. Las instalaciones viven en `.claude/settings.json` del proyecto (`enabledPlugins`, `extraKnownMarketplaces`). La matriz completa herramienta × capacidad agéntica se construye en la Fase 1 y se añade aquí.

## Marketplaces registrados (alcance: proyecto)

| Marketplace | Fuente | Commit revisado | Fecha de revisión | Licencia |
|---|---|---|---|---|
| `posit-dev-skills` | github.com/posit-dev/skills | `4400f97e7380` (2026-10-15) | 2026-10-16 | MIT |
| `anthropic-agent-skills` | github.com/anthropics/skills | `dbd4588f9e10` (2026-10-09) | 2026-10-16 | sin `LICENSE` detectado por la API de GitHub; revisar en Fase 1 |

## Plugins instalados y resultado de la cuarentena

| Plugin | Skills que aporta | SKILL.md revisados (sha256, 16 hex) | Hallazgos del escaneo | Decisión |
|---|---|---|---|---|
| `quarto@posit-dev-skills` | `quarto-authoring`, `brand-yml`, `alt-text` | quarto-authoring `57beae1419556214`; brand-yml `2fe8e36738342a42`; alt-text `0d33621f007e3d2a` | Solo menciones de instalación (`pip install shiny`, `jupyter-cache`) en texto explicativo; sin ejecución remota ni anulación de instrucciones | **usar existente** |
| `r-lib@posit-dev-skills` | `r-testthat`, `r-tidyverse-style`, `r-cli`, `r-cran-extrachecks`, `r-lifecycle`, `r-package-development`, `r-cli-app`, `r-mirai`, `r-cran-status`, `alt-text` | r-testthat `1ab412ca413fa9a1`; r-tidyverse-style `c04210c21f3d8a15`; r-cli `f9dfd60df5cd5b12`; r-package-development `b63848348d85c58c`; r-lifecycle `41d93fc540e0b015`; r-cran-extrachecks `b036fd03f70811b1`; r-cran-status `de903fbfb4d5e1db`; r-cli-app `3672e5750ce81d26`; r-mirai `26e19db91bdb16eb` | `install.packages` y `chmod +x` aparecen como instrucciones documentales de desarrollo de paquetes; `api_key` en r-mirai es un ejemplo de API de `mirai::everywhere()`; sin riesgo | **usar existente** |
| `document-skills@anthropic-agent-skills` | `pdf`, `docx`, `xlsx`, `pptx` | pdf `9f78b8359fbd4943`; xlsx `6712b39718fe8150`; docx `8017469ea95fb7d2` (pptx no revisado: no se usará para codebooks) | `password` solo en la sección de cifrado de PDF; sin riesgo | **usar existente** (los codebooks del INEI son PDF) |

No instalados tras revisión: `shiny`, `connect`, `ggsql`, `github`, `open-source`, `posit-dev` (posit) y `example-skills`, `claude-api`, `academy-guide`, `discernment-nudge` (anthropic): fuera del stack de Ronda 1 o redundantes con skills propias planificadas (`adversarial-review`). `posit-dev/critical-code-reviewer` (`9aa7f95787f2f236`) se revisó y queda como candidato para la skill `adversarial-review` de la Fase 3.

## MCP conectados en esta sesión (host; se registran, no se instalan en la imagen)

| MCP | Uso previsto | Estado |
|---|---|---|
| GitHub (vía `gh` CLI, no MCP) | repos, Actions, releases | activo |
| PubMed, Scite, bioRxiv/medRxiv, ClinicalTrials.gov, Consensus | skill `lit-review` con citas verificadas | conectados en la app |
| Mermaid (validate_and_render) | diagramas ISO 5807 (Fase 2) | conectado |
| mathlas, sympy-mcp (usuario) | ninguno en este proyecto | caídos; fuera del alcance |

## Pendiente (Fase 1, ítem 12)

DuckDB, DVC, Zenodo, Julia, `targets`, pre-commit/`lintr`: buscar skill oficial → comunitaria → propia; cada una con prueba mínima dentro del contenedor y eval. Verificación periódica de hashes: cuando `claude plugin marketplace update` cambie el commit, repetir la cuarentena antes de aceptar.
