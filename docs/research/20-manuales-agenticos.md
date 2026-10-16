---
item: 20
titulo: Manuales agénticos Claude Code vs Claude Cowork
modelo: sonnet
esfuerzo: medium
fecha: 2026-10-16
estado: borrador
---
# 20 — Manuales agénticos (Claude Code vs Claude Cowork)

## Pregunta
Qué soporta y qué no Cowork frente a Claude Code, qué lleva un manual mínimo de operación y cómo mantener una sola fuente para ambos manuales.

## Hallazgos
- Cowork usa la arquitectura agéntica de Claude Code dentro de Claude Desktop; lee y escribe solo en carpetas conectadas; skills, plugins y conectores salen de **Customize** (cuenta claude.ai) y no lee `~/.claude` del CLI (https://claude.com/docs/cowork/overview.md, 2026-10-16; https://support.claude.com/en/articles/13345190-get-started-with-cowork, 2026-10-16).
- Plugins: skills, commands, agents y `hooks/hooks.json` cargan en Cowork; LSP, output styles y `settings` del plugin se ignoran; `bin/` no se instala (https://claude.com/docs/plugins/platform-support, 2026-10-16).
- Un proyecto de Cowork reúne carpetas, instrucciones permanentes, enlaces y memoria; vive solo en el equipo (https://claude.com/docs/cowork/guide/projects.md, 2026-10-16).
- Permisos de Cowork: Manual, Auto y Skip; el borrado exige "Allow" explícito (https://support.claude.com/en/articles/13345190-get-started-with-cowork, 2026-10-16). La pestaña Code de Desktop lee los mismos settings que el CLI; `dontAsk` es solo CLI (https://code.claude.com/docs/en/desktop, 2026-10-16).
- Tareas programadas: corren en remoto, salvo las que necesitan archivos o apps locales, que corren en local (https://support.claude.com/en/articles/13854387-schedule-recurring-tasks-in-claude-cowork, 2026-10-16).
- El changelog de Desktop documenta `AGENTS.md` como respaldo de `CLAUDE.md` solo para Code (https://claude.com/docs/cowork/changelog, 2026-10-16).
- Best practices: `/clear` entre tareas no relacionadas, verificación ejecutable, CLAUDE.md breve y hooks para lo obligatorio (https://code.claude.com/docs/en/best-practices, 2026-10-16).
- Quarto: `_quarto-<perfil>.yml`, `--profile`, `.content-visible when-profile` y grupos de perfiles exclusivos existen; un perfil sin archivo se ignora en silencio (https://quarto.org/docs/projects/profiles.html, 2026-10-16).
- Si Cowork lee `CLAUDE.md`, `.claude/rules` o los hooks de `.claude/settings.json` de un repo, no está documentado **[provisional]**.

## Decisión propuesta
- Decisión: un solo `manual.qmd` con `.content-visible when-profile="code|cowork"` y grupo de perfiles `[code, cowork]`, mismas secciones comunes (índices y tabla en `_20-anexo-manuales.md`) | Alternativa descartada: YAML de secciones con script generador (más piezas) | Confianza: media.
- Decisión: tratar los hooks del repo como no garantizados en Cowork y exigir que ese manual lo declare | Alternativa descartada: asumir paridad | Confianza: media.

## Riesgos y provisional
- Soporte de CLAUDE.md, rules y hooks de proyecto en Cowork, y la contradicción local/remoto de las tareas programadas, se cierran con una prueba manual en Fase 3.

## Fuentes nuevas
- https://claude.com/docs/cowork/guide/plugins.md — instalar el plugin del proyecto en Cowork.
- https://claude.com/docs/third-party/claude-desktop/extensions.md — hooks y skills en Desktop.
