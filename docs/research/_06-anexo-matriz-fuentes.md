# Anexo 06 — Matriz de congelamiento aplicada (consultado 2026-10-16)

Niveles: 1 espejo público con DOI; 2 restringido con DOI; 3 receta + hash públicos, bytes en almacenamiento privado; 4 no espejar.

| fuente | riesgo | términos | tamaño | valor | frecuencia | nivel | condición para subir de nivel |
|---|---|---|---|---|---|---|---|
| ENDES (INEI) | medio (portal inestable) | consentimiento escrito para copia multiusuario; cita obligatoria (informe 05) | [provisional] ~1-5 GB/edición (estimación) | carga de enfermedad, servicios | anual | 3 | consentimiento escrito de INEI (infoinei@inei.gob.pe) sube a 2 |
| ENAHO (INEI) | medio | misma política INEI, inferida [provisional] | [provisional] ~1-3 GB/año | impacto, servicios | anual | 3 | consentimiento escrito de INEI sube a 2 |
| Censos INEI | medio | política INEI [provisional] | [provisional] varios GB | espacial, carga de enfermedad | decenal | 3 | consentimiento de INEI sube a 2 |
| MEF SIAF / Consulta Amigable | alto (cambios de plataforma) | sin licencia visible [provisional] | [provisional] GB (estimación) | impacto, servicios | diaria/mensual | 3 | licencia o comunicado de libre disposición verificado sube a 1 |
| RENIPRESS (SUSALUD) | bajo | ODC-By | [provisional] <100 MB | servicios de salud | periódica | 1 | — |
| RENAES / MINSA-IPRESS | medio | License Not Specified | [provisional] <100 MB | servicios de salud | periódica | 3 | licencia explícita o autorización sube a 1 |
| SUSALUD (SIS) | bajo | ODC-By | [provisional] MB-GB | servicios de salud | periódica | 1 | — |
| HIS-MINSA | medio | sin verificar; ODC-By dudoso | [provisional] GB | carga de enfermedad, servicios | mensual | 3 | licencia verificada sube a 1 con partición |
| INFORHUS (personal) | medio | sin verificar [provisional] | [provisional] <1 GB | servicios de salud | periódica | 3 | licencia verificada sube a 1 |
| SINADEF | medio | sin verificar; registros de personas | [provisional] cientos de MB | carga de enfermedad, predicción | diaria | 3 | licencia y anonimización verificadas sube a 1 |
| Vigilancia CDC-MINSA | alto (cambia sin aviso) | sin verificar | [provisional] MB | predicción, carga de enfermedad | semanal | 3 | licencia verificada sube a 1 |
| EsSalud | alto | sin verificar [provisional] | [provisional] desconocido | servicios de salud | variable | 3 | acuerdo institucional sube a 2 |
| INCOR (paciente) | n/a | datos personales (Ley 29733) | n/a | impacto clínico | n/a | 4 | solo con comité de ética y acuerdo de uso; nunca público |
| SENAMHI | alto | condiciones ilegibles [provisional] | [provisional] MB-GB | predicción, espacial | diaria | 3 | términos leídos con uso libre sube a 1 |
| ERA5 (Copernicus) | bajo | CC-BY | ~36 GB/variable-año global (estimación); recorte a Perú mucho menor | predicción, espacial | diaria, latencia 5 días | 1 (recorte Perú) | — |
| CHIRPS | alto (v2 termina dic-2026) | dominio público | ~14 MiB/mes (~7,6 GB 1981-2026, cálculo) | predicción, espacial | mensual | 1 | — |
| NASA POWER | bajo | sin verificar [provisional] | [provisional] pequeño por punto | predicción | diaria | 3 | términos verificados sube a 1 |
| Defensoría (conflictos) | medio | sin aviso de reutilización | [provisional] MB | impacto, espacial | mensual | 3 | autorización o licencia sube a 1 |
| ACLED | bajo | EULA: sin redistribución, restricción de IA | [provisional] MB-GB | impacto, predicción | semanal | 4 | licencia institucional propia; solo salidas transformadoras |
| GDELT | bajo | espejo permitido con cita y enlace | 4-8 MB/día (~3 GB/año) | predicción | diaria | 1 (recorte Perú) | — |
| Google Mobility | alto (discontinuado 2022) | ToS de Google sin leer | [provisional] >10 MB (no medido) | impacto, predicción | cerrada | 3 | ToS permite redistribuir sube a 1 |
| Datos espaciales municipales/regionales | alto | sin verificar | [provisional] MB-GB | espacial | irregular | 3 | licencia verificada sube a 1 |

Conteo: nivel 1 = 5; nivel 2 = 0; nivel 3 = 15; nivel 4 = 2. Los tamaños marcados como estimación son cálculo propio o supuesto.
