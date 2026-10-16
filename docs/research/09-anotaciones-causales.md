---
item: 9
titulo: Anotaciones causales por estudio
modelo: sonnet
esfuerzo: medium
fecha: 2026-10-16
estado: borrador
---
# 9 — Anotaciones causales por estudio

## Pregunta
Cómo registrar el rol causal de una variable dentro de un estudio (`variable_usage`) sin que se filtre al registro global, y qué formato de DAG versionar.

## Hallazgos
- dagitty documenta tres estados de variable: exposure, outcome y latent (`setVariableStatus`), más `adjustedNodes`; exposición y desenlace pueden ir en el propio grafo (https://cran.r-project.org/web/packages/dagitty/dagitty.pdf, 2026-10-16).
- La etiqueta `selected` de la sintaxis textual no está documentada en el manual CRAN; solo aparece el concepto de variable de selección en `canonicalize` **[provisional]** (https://cran.r-project.org/web/packages/dagitty/dagitty.pdf, 2026-10-16).
- ggdag: `dagify` acepta `exposure`, `outcome`, `latent`, `labels`, `coords`; `tidy_dagitty` parte de un objeto dagitty (https://r-causal.github.io/ggdag/reference/dagify.html, 2026-10-16; https://r-causal.github.io/ggdag/reference/tidy_dagitty.html, 2026-10-16).
- Tennant et al. 2021 definen confusor, mediador, colisionador y exposición competidora, y recomiendan publicar el DAG y declarar los conjuntos de ajuste (https://academic.oup.com/ije/article/50/2/620/6012193, 2026-10-16).
- bnlearn solo escribe DOT (`write.dot`); DoWhy acepta GML y networkx, no DOT en la guía consultada (https://www.bnlearn.com/documentation/man/foreign.html, 2026-10-16; https://www.pywhy.org/dowhy/main/user_guide/modeling_causal_relations/specifying_causal_graph.html, 2026-10-16).
- RECORD 7.1 exige la lista de códigos y algoritmos para exposiciones, desenlaces y confusores (https://journals.plos.org/plosmedicine/article?id=10.1371/journal.pmed.1001885, 2026-10-16). TRIPOD+AI pide definir desenlace (8a) y predictores (9b) (https://pmc.ncbi.nlm.nih.gov/articles/PMC11019967/, 2026-10-16).
- Strategus guarda cohortes y covariables por estudio en un JSON, sin roles causales globales (https://ohdsi.github.io/Strategus/articles/CreatingAnalysisSpecification.html, 2026-10-16).
- STROBE (ítems de confusores), IPUMS, ClinicalTrials.gov, pcalg y los roles instrumento, proxy y modificador no pudieron verificarse **[provisional]**.

## Decisión propuesta
- Decisión: `variable_usage(study_id, variable_id, rol, dag_ref, dag_node, dag_sha256, estimand, notas, cita_doi)`; rol enumerado: exposure, outcome, confounder, mediator, collider, instrument, effect_modifier, proxy, selection, competing_exposure, predictor, covariate_noncausal, unclassified **[no oficial]** | Alternativa descartada: columna `rol` en `variable` | Confianza: media.
- Decisión: DAG como archivo `.dagitty` (texto) versionado en el repo del estudio, con `dag_sha256`; DOT/GML derivados | Alternativa descartada: JSON propio | Confianza: media.
- Decisión: `variable` carece de campos de rol; clave compuesta y vista de solo lectura por estudio; test que falle si `variable` contiene "rol" | Alternativa descartada: rol "habitual" | Confianza: alta.

## Riesgos y provisional
- Taxonomía de roles propia, a validar en Fase 2 con un estudio piloto; sintaxis `selected` y guías STROBE por verificar.

## Fuentes nuevas
- https://www.dagitty.net/learn/graphs/ — enlaza el artículo "Describing covariate roles" y la sintaxis oficial.
- https://www.strobe-statement.org/ — texto exacto de los ítems 7, 12 y 16 sobre confusores.
