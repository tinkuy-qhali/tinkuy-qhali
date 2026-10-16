---
item: 13
titulo: Nomenclatura, carpetas, bitácoras y meta-aprendizaje
modelo: sonnet
esfuerzo: medium
fecha: 2026-10-16
estado: borrador
---
# 13 — Nomenclatura, bitácoras y meta-aprendizaje

## Pregunta
Qué convención de nombres, rotación de bitácoras y política de lecciones conviene al repo, y si un meta-aprendedor se justifica en Ronda 1.

## Hallazgos
- Anthropic: `.claude/rules/` admite archivos `.md` temáticos con nombre descriptivo (`testing.md`), descubiertos de forma recursiva; CLAUDE.md debe quedar bajo 200 líneas (https://code.claude.com/docs/en/memory, 2026-10-16).
- Las skills viven en `.claude/skills/<nombre>/SKILL.md`; `name` por defecto es el directorio; `synced` y el prefijo `anthropic-skills` están reservados (https://code.claude.com/docs/en/skills, 2026-10-16).
- La memoria automática carga las primeras 200 líneas o 25 KB de `MEMORY.md`; el detalle va en archivos temáticos (https://code.claude.com/docs/en/memory, 2026-10-16).
- Al compactar se conservan peticiones y fragmentos clave, pero instrucciones tempranas pueden perderse; "Compact Instructions" en CLAUDE.md controla qué se preserva (https://code.claude.com/docs/en/how-claude-code-works, 2026-10-16).
- Si una regla ya se cumple sola, se borra o se convierte en hook; los hooks son deterministas, CLAUDE.md es consultivo (https://code.claude.com/docs/en/best-practices, 2026-10-16).
- Bryan: nombres legibles por máquina (sin espacios ni acentos), por humanos y ordenables (prefijo numérico con ceros, fechas ISO 8601) (https://speakerdeck.com/jennybc/how-to-name-files, 2026-10-16).
- MADR 4.0.0 (2024-09-17): `NNNN-titulo-con-guiones.md` en `docs/decisions` (https://adr.github.io/madr/, 2026-10-16); Nygard popularizó los ADR (2011) (https://adr.github.io/, 2026-10-16).
- Keep a Changelog: categorías Added/Changed/Deprecated/Removed/Fixed/Security, fechas ISO, sección Unreleased (https://keepachangelog.com/en/1.1.0/, 2026-10-16).
- rrtools: `analysis/{paper,figures,data/raw_data,data/derived_data}` (https://github.com/benmarwick/rrtools, 2026-10-16); Cookiecutter DS: `data/{raw,interim,processed,external}` y cuadernos numerados con iniciales (https://cookiecutter-data-science.drivendata.org/, 2026-10-16); TIER: `Data/InputData`, `Scripts`, Master Script (https://www.projecttier.org/tier-protocol/protocol-4-0/, 2026-10-16).
- Rotación en otros proyectos agénticos y costo de meta-aprendedores: sin fuente. **[provisional]**

## Decisión propuesta
- Decisión: `kebab-case` ASCII; fechas `YYYY-MM-DD`; ADR `NNNN-titulo.md`; informes `NN-tema.md`; bitácoras `YYYY-MM-DD-faseX-tema.md`; ramas `tipo/tema`; tags `vX.Y.Z` (detalle en el anexo `_13-anexo-convenciones.md`) | Alternativa descartada: mayúsculas y espacios | Confianza: alta.
- Decisión: rotar `docs/agent-log/` al cerrar fase o superar 300 líneas por archivo; mover a `docs/agent-log/archivo/AAAA/` lo de más de 90 días, dejando índice; lecciones (`LESSONS.md`) ≤ 100 líneas, promovidas por el humano a regla tras 2 recurrencias y a hook si deben cumplirse siempre | Alternativa descartada: borrar bitácoras | Confianza: media.
- Decisión: meta-aprendedor en Ronda 2, no antes; en Ronda 1 basta una revisión manual al cierre de fase con compuerta humana | Alternativa descartada: agente autónomo permanente | Confianza: media.

## Riesgos y provisional
- Umbrales (300 líneas, 90 días, 100 líneas) son estimaciones **[provisional]**; ajustarlos tras la Fase 2. Activar meta-aprendedor si hay más de 3 cambios de política por fase.

## Fuentes nuevas
- https://adr.github.io/madr/decisions/ — ejemplos reales de ADR y estados (superseded) para fijar el ciclo de vida.
- https://code.claude.com/docs/en/hooks-guide — criterios técnicos para promover lecciones a hooks.
