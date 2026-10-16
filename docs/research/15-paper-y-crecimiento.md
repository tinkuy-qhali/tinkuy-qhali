---
item: 15
titulo: Paper y crecimiento (venues y regla capítulo vs repo)
modelo: sonnet
esfuerzo: medium
fecha: 2026-10-16
estado: borrador
---
# 15 — Paper y crecimiento

## Pregunta
Qué venues encajan con el paper del ecosistema y con un futuro data paper ENDES, y cuándo IPUMS, OHDSI y nf-core hacen que algo sea capítulo o repo propio.

## Hallazgos
- JOSS exige licencia OSI, tests automatizados, repo clonable sin registro, al menos seis meses de historial público y "esfuerzo académico sustancial"; sin APC; revisión abierta; archivo Zenodo tras aceptar (https://joss.readthedocs.io/en/latest/submitting.html, 2026-10-16).
- Gates Open Research (Data Note, Software Tool Article) solo admite autores con financiamiento Gates, datos CC0 (https://gatesopenresearch.org/for-authors/article-guidelines/data-notes, 2026-10-16).
- Scientific Data: APC, datos depositados en repositorio público antes de enviar, CC BY **[provisional: nature.com bloqueó la lectura]** (https://www.nature.com/sdata/for-authors, 2026-10-16).
- Data in Brief: APC hasta 530 USD, CC BY **[provisional: fuente secundaria]** (https://doaj.org/toc/57bade9c54a7467cafffdca2f5b7b99b, 2026-10-16).
- RPMESP lista "Artículo original", "Original breve", "Revisión", etc.; no hay tipo explícito de recurso o software **[provisional]** (https://rpmesp.ins.gob.pe/public/journals/1/Declaracion_Jurada_RPMESP_ES.docx, 2026-10-16).
- HADES: un paquete por repo, Apache 2.0, tests (~80 %), semver (https://ohdsi.github.io/Hades/packageRequirements.html, 2026-10-16; https://ohdsi.github.io/Hades/releaseProcess.html, 2026-10-16).
- `ohdsi-studies` tiene unos 191 repos, uno por estudio, con plantilla `StudyRepoTemplate` (https://github.com/ohdsi-studies, 2026-10-16).
- nf-core: pipelines con MIT, semver, lint y una sola pipeline canónica por tipo de análisis; propuesta previa; módulos en el monorepo `nf-core/modules` (https://nf-co.re/docs/contributing/adding_pipelines, 2026-10-16; https://github.com/nf-core/modules, 2026-10-16).
- IPUMS Global Health agrupa DHS, MICS y PMA; PMA tiene su propia beca y PIs; ISRDI da soporte común (https://www.ipums.org/projects/ipums-global-health, 2026-10-16) **[no oficial]**.

## Decisión propuesta
- Decisión: ecosistema, principal JOSS (secundaria: Scientific Data como Article de infraestructura, **provisional**); falta historial ≥6 meses, CI y release Zenodo | Alternativa descartada: Gates | Confianza: media.
- Decisión: data paper ENDES, principal Scientific Data; secundaria Data in Brief; RPMESP solo si la nota es metodológica en español; falta repositorio de datos con DOI y licencia | Alternativa descartada: JOSS (no es software) | Confianza: baja.
- Decisión: nace un repo si se cumple ≥1 criterio de la spec (licencia, ciclo, dominio, tamaño, equipo); licencia y ciclo propios pesan más; el resto es capítulo | Alternativa descartada: repo por estudio como `ohdsi-studies` | Confianza: media.

## Riesgos y provisional
- Tarifas y plazos de Scientific Data y Data in Brief, y normas completas de RPMESP, sin verificar; cerrar en Fase 4.
- IPUMS: criterio de separación por proyecto no verificado.

## Fuentes nuevas
- https://www.nature.com/sdata/publish/for-authors — confirmar APC, tipos y repositorios exigidos al desbloquear acceso.
- https://rpmesp.ins.gob.pe/index.php/rpmesp/about/submissions — normas vigentes de tipos de artículo y costos.
