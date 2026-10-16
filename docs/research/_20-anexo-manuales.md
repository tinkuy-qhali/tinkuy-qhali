# Anexo 20 — Índices, tabla de diferencias y fuente única

## Manual Claude Code (perfil `code`, 11 secciones)
1. Qué es este repo y para quién (alcance, datos de salud: qué nunca se pega).
2. Requisitos: Docker Desktop, Git, gh, Claude Code (enlace a install-agentic / install-manual).
3. Arranque: `start.sh` / `start.bat`, `claude login` la primera vez dentro del contenedor.
4. Sesión dentro del contenedor: qué vive en la imagen (R, Python, Julia, DVC, Quarto) y qué en el host.
5. Una fase por sesión: `/clear` entre fases, `/rewind`, `/resume`, `/compact`; plan mode antes de cambios amplios.
6. Skills y subagentes disponibles del repo (tabla nombre, para qué, cómo invocar).
7. Qué pedir: tareas con criterio de verificación ejecutable; qué no pedir (push, borrados, descargas, datos reales).
8. Permisos y hooks activos: qué bloquea el hook PreToolUse, cómo leer una denegación.
9. Cómo leer la bitácora (ubicación, formato, qué entradas son decisiones vs. ejecuciones).
10. Qué hacer si falla (`/doctor`, `/context`, logs del contenedor).
11. Seguridad y reglas de sesión (ADR antes de cambios irreversibles, resúmenes de 5 líneas).

## Manual Claude Cowork (perfil `cowork`, 10 secciones)
1. Qué es este repo y para quién (igual que Code).
2. Requisitos: plan Pro/Max/Team/Enterprise, Claude Desktop reciente, Windows o macOS.
3. Conectar la carpeta del repo (o crear un proyecto Cowork con carpeta e instrucciones).
4. Instalar el plugin del proyecto desde **Customize > Plugins** (skills no se leen de `~/.claude`).
5. Instrucciones del proyecto: pegar el contenido esencial de CLAUDE.md como instrucciones del proyecto **[provisional]**.
6. Modos de permiso (Manual/Auto/Skip): usar Manual; nunca Skip con datos reales.
7. Qué pedir y qué no (sin ejecución en contenedor garantizada; sin push).
8. Tareas programadas: cuáles corren en remoto y cuáles en local.
9. Cómo leer la bitácora.
10. Límites: lo que solo existe en Code (ver tabla).

## Tabla de diferencias
| Aspecto | Claude Code (terminal / pestaña Code) | Cowork | Fuente |
|---|---|---|---|
| Alcance de archivos | El directorio de trabajo y permisos | Solo carpetas conectadas | support 13345190 |
| CLAUDE.md / rules | Documentado (memory) | No documentado; proyecto con instrucciones propias **[provisional]** | cowork/guide/projects |
| Skills | `.claude/skills` y plugins | Solo las de Customize/cuenta; no lee `~/.claude` | cowork/overview |
| Plugins (skills, commands, agents, hooks, MCP remoto) | Cargan | Cargan; MCP local solo si la sesión es local | plugins/platform-support |
| LSP, output styles, `settings` de plugin, `bin/` | Cargan | Ignorados / no instalable | plugins/platform-support |
| Hooks en `.claude/settings.json` | Sí | No documentado **[provisional]**; hooks de plugin sí cargan | platform-support |
| Subagentes | Personalizados en `.claude/agents` | Coordinación de sub-agentes integrada; personalizados vía plugin `agents/` | cowork/overview, platform-support |
| Permisos | default, acceptEdits, plan, auto, bypass, dontAsk + reglas allow/ask/deny | Manual, Auto, Skip; política por conector | support 13345190, code desktop |
| Worktrees | `isolation: worktree`, `.claude/worktrees` | Changelog menciona sesiones en worktree en Cowork; uso no documentado como flujo **[provisional]** | cowork/changelog |
| Tareas programadas | Routines (nube, ≥1 h) y `/loop` | Scheduled (remoto, o local si requiere archivos/apps) | support 13854387 |
| Sandbox / contenedor del repo | Se puede lanzar dentro del contenedor | No: corre en el equipo o en la nube de Anthropic | support 13345190 |

## Mecanismo de fuente única
- Estructura: `docs/manual/_quarto.yml` con `profile: group: [[code, cowork]]` y `default: code`; `_quarto-code.yml` y `_quarto-cowork.yml` fijan título y salida; `manual.qmd` con secciones comunes y bloques `::: {.content-visible when-profile="cowork"}` / `unless-profile`.
- Render: `quarto render docs/manual --profile code` y `--profile cowork`. Verificado en la página de perfiles: perfil por flag o QUARTO_PROFILE, contenido condicional por `when-profile`, grupos exclusivos.
- Guardas: un perfil mal escrito se ignora en silencio, así que un test de CI debe comprobar que ambos HTML contienen sus encabezados clave y no los del otro.
- Alternativa descartada: YAML de secciones más script (más código propio sin ventaja).
