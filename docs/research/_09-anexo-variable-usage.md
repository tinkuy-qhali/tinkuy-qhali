# Anexo: esquema mínimo de variable_usage

| Campo | Tipo | Nota |
|---|---|---|
| study_id | FK | parte de la clave |
| variable_id | FK a registro global | parte de la clave |
| rol | enum | exposure, outcome, confounder, mediator, collider, instrument, effect_modifier, proxy, selection, competing_exposure, predictor, covariate_noncausal, unclassified |
| estimand | texto | ej. efecto total de X sobre Y |
| dag_ref | ruta | archivo .dagitty en el repo del estudio |
| dag_node | texto | nombre del nodo en el DAG |
| dag_sha256 | hash | del archivo DAG en el commit citado |
| notas | texto | justificación; arcos omitidos |
| cita_doi | texto | DOI del estudio/protocolo |

Clave: (study_id, variable_id, rol). Contra la filtración: la tabla global `variable` no tiene columna de rol; ninguna vista global agrega `rol`; un test falla si aparece; la UI muestra el rol siempre junto a study_id.
Mapeo a guías: rol=confounder/effect_modifier para STROBE y RECORD 7.1; predictor/outcome para TRIPOD+AI 8a/9b.
