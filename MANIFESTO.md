---
title: "Manifiesto"
---

# Manifiesto de tinkuy-qhali

Versión 0.1 (borrador de la Fase 0.6; se revisa en la Fase 3 con los hallazgos de la investigación). Cada principio enuncia **cómo se verifica**, porque un principio que no se puede comprobar es una intención, no un compromiso.

1. **Los datos crudos no se tocan y no viven en git.** `raw/` es un espejo byte a byte con `manifest.json` (origen, fecha, SHA-256, tamaño, términos vigentes, nivel de congelamiento). *Verificación:* un hook bloquea `git add raw/`; el resolutor del `registry` recupera cada archivo por su hash.
2. **Toda variable harmonizada tiene procedencia.** Sin DOI/URL o `study_id`, fecha y autor, el validador rechaza la variable. *Verificación:* `variable_registry` falla el test si falta procedencia.
3. **El rol causal es de la variable dentro de un estudio, nunca global.** *Verificación:* `variable_usage` exige `study_id` y referencia a un DAG.
4. **Nada crítico se da por hecho sin ejecutar su test.** Validadores, hooks, resolutor, bootstrap y `sync-template` tienen tests que corren en CI y dentro del contenedor. *Verificación:* `tests/` en verde en cada PR.
5. **Cada decisión irreversible tiene un ADR antes de implementarse.** *Verificación:* `docs/adr/` con estado y fecha; el agente adversarial de pre-release busca decisiones sin ADR.
6. **Se documenta antes de codificar.** Pensar por escrito es parte del método (en la línea abierta y pedagógica de Scott Cunningham; se concreta en la Fase 1, ítem 25). *Verificación:* cada skill y cada etapa del pipeline enlaza al documento que la justifica.
7. **Se redistribuye solo lo que la licencia permite; ante duda, receta + hash.** *Verificación:* cada mart declara licencia efectiva y URL de los términos de la fuente; `audit-license` corre antes de cada release.
8. **Reproducible por cualquiera, con o sin agentes.** Un comando (`run.sh`/`run.bat`) ejecuta el pipeline completo dentro del contenedor y produce el reporte. *Verificación:* el benchmark lo prueba en una carpeta limpia.
9. **Los agentes leen metadata, no datos.** Manifiestos, diccionarios estructurados y salidas de validadores; nunca microdatos. *Verificación:* política de tokens y hooks de lectura.
10. **Los residuos se limpian.** Lo regenerable se regenera; lo temporal se borra al cerrar sesión; lo que se conserva tiene permanencia justificada. *Verificación:* `SessionEnd` archiva la bitácora y poda worktrees; el benchmark mide residuos.
11. **Lo que se preserva se espeja.** Niveles de congelamiento explícitos por fuente; `MIRRORS.md` con quién, qué versión, hash y fecha de verificación; plan 3-2-1. *Verificación:* script de verificación periódica de mirrors.
12. **Las conclusiones citan fuentes verificables.** Documentación oficial con URL y fecha; sin fuente, la decisión se marca provisional. *Verificación:* los informes de investigación fallan el chequeo si no traen URL y fecha.
