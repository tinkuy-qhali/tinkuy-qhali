# Mensaje de arranque de la Fase 1 (pegar tras `/clear`)

```text
Continúa el proyecto tinkuy-qhali en la Fase 1 (investigación por subagentes). Lee primero, en este orden: docs/agent-log/2026-10-16-fase0-6-estado.md (estado y lecciones), docs/adr/0000-alineacion.md (decisiones y plan aprobado) y la sección "Fase 1" de _bootstrap/PROMPT-v4-pe-health-data-commons.md (los 26 ítems). No repitas la Fase 0 ni rehagas el montaje: la imagen, los repos, el sitio, DVC y Zenodo Sandbox ya están y tests/test_bootstrap.sh da 22/22.

Reglas de la fase: subagentes de investigación con isolation worktree, a lo sumo 4 en paralelo (machine-profile.json); cada informe en docs/research/NN-<tema>.md con ≤ 400 palabras, URL y fecha por cada afirmación, y una sección "Fuentes nuevas" con 2 propuestas; modelo pequeño para los ítems de catálogo (12, 16, 17) y grande para 1, 3, 11, 18 y 22. El ítem 1 revisa y corrige la configuración de Claude Code (ADR 0001) contra documentación oficial. El ítem 22 corre sus benchmarks dentro del contenedor con docker compose run (ENDES 2024 módulo 1629 ya está en raw/). Consolida en docs/research/00-informe-investigacion.md con la tabla de decisiones y responde las cinco preguntas finales de la Fase 1. Criterio de aceptación: tools/check_research.py (créalo) valida cada informe; ≥ 27 archivos en docs/research/.

Mantén las dos reglas de la sesión: ADR antes de cualquier decisión irreversible y nada crítico sin ejecutar su test. Empieza mostrándome el plan de subagentes (lotes de 4, con modelo y esfuerzo por ítem) y espera mi aprobación antes de lanzarlos. Al terminar la fase: resumen de 5 líneas y la decisión que necesitas de mí.
```

Contexto que el mensaje da por sentado y que sobrevive al `/clear`: la memoria del proyecto (`~/.claude/projects/.../memory/`), los ADR 0000–0007, la bitácora de la Fase 0.6 y `docs/tooling/skills-registry.md`.
