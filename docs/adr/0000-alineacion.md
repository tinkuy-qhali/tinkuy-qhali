# ADR 0000 — Alineación inicial (Fase 0)

- **Estado:** aceptado
- **Fecha:** 2026-10-16
- **Decisores:** Percy Soto-Becerra (usuario); Claude Code (arquitecto propuesto)
- **Fuente:** `_bootstrap/PROMPT-v4-pe-health-data-commons.md` (se archiva en `docs/archive/bootstrap/` al cerrar la Fase 3)

## Contexto

Antes de crear archivos, la especificación exige una fase de alineación interactiva: perfil de la máquina, configuración de Claude Code, reflexión, preguntas estructuradas, lluvia de ideas de arquitectura, votación y plan por fases. Este ADR registra el resultado completo para que cualquier sesión futura (humana o agéntica) reconstruya el *por qué* sin releer la conversación.

## Perfil de la máquina (0.0)

Generado por `tools/profile_machine.py` (solo librería estándar; `machine-profile.json` está en `.gitignore` y se regenera en cada bootstrap y `SessionStart`).

| Ítem | Valor |
|---|---|
| OS / shell | Windows 10 Pro for Workstations 19045; Git Bash; WSL 3.0.3 (Ubuntu y docker-desktop, WSL2) |
| CPU / RAM | Xeon E3-1575M v5, 4 físicos / 8 lógicos; 31.9 GB |
| Disco / GPU | C: 1 TB (382 GB libres, único disco); NVIDIA Quadro P3000 6 GB |
| Presente | Docker 29.5.3 + Compose 5.1.4, Git 2.54, gh 2.95, Claude Code 2.1.195 → 2.1.301 tras `claude update`, Python 3.14.6, uv 0.11.19, R 4.6.0, Quarto 1.9.37, Node 24 |
| Ausente | Julia, DVC, DuckDB; `.wslconfig`; `core.excludesfile` |
| Red | Internet directo sin proxy; GitHub API, portal INEI y Zenodo Sandbox alcanzables |
| Derivado | contenedor 7 CPU lógicos / 24 GB; `targets` workers = 3; subagentes ≤ 4; worktrees ≤ 4; DuckDB en memoria (límite 12.8 GB); descargas completas |

Herramientas requeridas en el host (Docker Desktop, Git, gh, Claude Code): las cuatro presentes; no hizo falta `winget`.

## Reflexión inicial (0.1)

El objetivo es un *research compendium* agéntico y clonable: bytes crudos fuera de git resueltos por hash, semántica en un `cdm` versionado, y una plantilla que codifica políticas (permisos, hooks, skills) para que Claude Code opere con poco contexto y sin residuos. El producto es la infraestructura de confianza (manifiestos, procedencia, licencias verificadas, mirrors, benchmark), no un dataset.

Premisas consideradas riesgosas y mitigación acordada:

1. **Todo dentro del contenedor desde 0.6, en Windows.** La sesión de la app corre en el host; un bind-mount NTFS→Linux es 5–10× más lento. Mitigación: repo en `C:\`, pero `renv`, caché DVC, `raw/` y depot Julia en volúmenes nombrados; comandos de pipeline vía `docker compose run`.
2. **OHDSI como columna vertebral semántica para encuestas.** Licencias heterogéneas (SNOMED exige membresía nacional; Perú no es miembro), sin modelo de pesos/estratos/PSU, mapeo manual masivo. Mitigación: adoptar el *formato* OHDSI (`concept`, `concept_relationship`, rangos locales ≥ 2.000.000.000) con vocabularios propios; estándar solo donde la licencia y el valor lo justifiquen (ADR 0003).
3. **Julia + R + Python en una imagen desde el día uno.** Imagen de 6–9 GB y builds largos en 4 núcleos. Mitigación: Julia en una etapa del `Dockerfile` controlada por *build-arg*; el benchmark de la Fase 1 (ítem 22) decide si entra en la imagen por defecto.

## Respuestas del usuario (0.2)

### Tanda 1 — datos del usuario

| Pregunta | Respuesta | Estado |
|---|---|---|
| Identidad para citas | Percy Soto-Becerra, ORCID 0000-0001-5332-9254; afiliación primaria Universidad Privada del Norte (UPN); secundaria DATAVIDENCE SCIENTIFIC CONSULTING | Confirmado |
| GitHub | Nueva organización dedicada `tinkuy-qhali`, creada por el usuario en el navegador | Confirmado |
| Lenguaje principal | R (`targets` + `renv`); Python (`uv`) y Julia como procesos independientes con Parquet como contrato | Confirmado |
| Carpetas | Código en `C:\pe-health-data-commons`; datos y cachés en volúmenes nombrados de Docker | Confirmado |
| Nube para DVC | Cloudflare R2 (S3-compatible, 10 GB gratis, sin egreso); credenciales las gestiona el usuario | Confirmado |
| Políticas previas | Empezar de cero; `health-r-*`, `datavidence-template-project`, `psotobverse-utils` solo como referencia | Confirmado |
| Backups físicos | Ninguno aún; plan 3-2-1 con NAS UPN y disco frío como pendientes | Provisional |

### Tanda 2 — decisiones irreversibles

| Decisión | Respuesta | ADR |
|---|---|---|
| Modelo de datos | CDM propio por capas + formato OHDSI para vocabularios | 0003 |
| Licencias | Código MIT; derivados CC-BY-4.0 condicionada al nivel de congelamiento | 0004 |
| Visibilidad | Repos públicos desde el commit 1 | 0002 |
| Fuentes Ronda 2 | Solo ENDES (un módulo, una edición, ≥ 3 iteraciones) | — |
| Nombre | `tinkuy-qhali` | 0005 |

## Lluvia de ideas (0.3)

| Criterio | A. Monorepo | B. Multirepo puro (5 tipos) | C. Híbrido con capítulos |
|---|---|---|---|
| Forma | Un repo con `template/`, `cdm/`, `registry/`, `sources/`, `studies/` | Un repo por tipo y por instancia | 3 repos núcleo + repos por fuente solo si cumplen criterios; estudios como capítulos |
| Contratos | Ninguno | 4 + `cdm.lock`/`template.lock` por repo | 2 + `template.lock`; capítulos comparten lockfile |
| GitHub template | No | Sí | Sí, con modo consumidor |
| DOI / licencias | Uno para todo | Por fuente | Por repo núcleo y por fuente; capítulos heredan |
| CI (equipo de 1) | 1 | 4–6 en Ronda 1 | 3 en Ronda 1 |
| Crecimiento | Repo engorda | Explosión de repos | Criterio explícito para abrir repo |
| Riesgo | Sin separación de licencia/DOI | Coordinación y deriva | Umbral capítulo→repo mal decidido (mitigado con ADR + skill) |
| Precedentes | research compendium | OHDSI, nf-core | IPUMS, nf-core `modules` |

## Votación (0.4)

- Voto del agente: **C**, porque la plantilla debe ser un GitHub template real (descarta A) y un equipo de una persona no sostiene B en Ronda 1.
- Voto del usuario: **C**.
- Resultado: unánime. Detalle en ADR 0002.

## Plan por fases (0.5)

Aprobado el 2026-10-16. Copia íntegra con criterios de aceptación ejecutables en `docs/agent-log/2026-10-16-fase0-plan.md`. Resumen: F0-cierre (este ADR, configuración, git) → F0.6 montaje (contenedor, GitHub, sitio, DVC + R2, Zenodo Sandbox, skills) → F1 investigación (26 ítems) → F2 arquitectura → F3 scaffold + benchmark R1 → F4 piloto ENDES ≥ 3 iteraciones → F5 identidad/explorador/paper → F6 guía y prompts.

## Consecuencias

- Toda decisión irreversible posterior exige ADR antes de implementarse; nada crítico se da por hecho sin ejecutar su test.
- Lo marcado como *provisional* se revisa en la Fase 1 (ítem 1 revisa la configuración; ítem 5 las licencias; ítem 7 los backups).
