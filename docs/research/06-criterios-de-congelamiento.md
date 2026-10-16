---
item: 6
titulo: Criterios de congelamiento
modelo: sonnet
esfuerzo: medium
fecha: 2026-10-16
estado: borrador
---
# 06 — Criterios de congelamiento

## Pregunta
¿Qué nivel de espejo (1 a 4) corresponde a cada fuente y es compatible CC-BY-4.0 con sus derivados? Matriz en `_06-anexo-matriz-fuentes.md`.

## Hallazgos
- ODC-By: un Derivative Database comunicado públicamente solo puede ofrecerse bajo ODC-By y no se puede sublicenciar; un Produced Work solo exige aviso (https://opendatacommons.org/licenses/by/1-0/, 2026-10-16).
- La página de licencias compatibles de CC no menciona CC BY ni ODC-By; el veredicto es lectura propia (https://creativecommons.org/share-your-work/licensing-considerations/compatible-licenses/, 2026-10-16).
- CHIRPS es dominio público, pesa unos 14 MiB por mes y la versión 2 termina tras diciembre de 2026 (https://www.chc.ucsb.edu/data/chirps, 2026-10-16; https://data.chc.ucsb.edu/products/CHIRPS-2.0/global_monthly/tifs/, 2026-10-16).
- ERA5 es CC-BY y se actualiza a diario; no publica tamaño (https://cds.climate.copernicus.eu/datasets/reanalysis-era5-single-levels?tab=overview, 2026-10-16). Estimo ~36 GB por variable y año global sin comprimir **[provisional]** (https://catalog.pangeo.io/browse/master/atmosphere/era5_hourly_reanalysis_single_levels_sa, 2026-10-16).
- GDELT: un zip diario de eventos pesa 4–8 MB, unos 3 GB al año (http://data.gdeltproject.org/events/index.html, 2026-10-16).
- ACLED: licencia no sublicenciable; solo se publica material transformador (https://acleddata.com/eula, 2026-10-16).
- Google Mobility: discontinuado en 2022, ToS sin leer, tamaño no medido **[provisional]** (https://www.google.com/covid19/mobility/, 2026-10-16).
- ENDES: el servidor de INEI rechazó la conexión, así que tamaño y frecuencia quedan **[provisional]**; términos del informe 05 (http://webinei.inei.gob.pe/anda_inei/index.php/catalog/817/accesspolicy, 2026-10-16).

## Decisión propuesta
- Decisión: reglas en orden. R1 términos que prohíben redistribuir o sin licencia verificada, nivel 3 o 4. R2 licencia abierta y riesgo alto, nivel 1 con partición o recorte a Perú. R3 datos personales o de paciente, nivel 4. R4 licencia abierta y riesgo bajo, nivel 1 si el recorte pesa menos de 10 GB; si no, nivel 3. R5 nivel 2 solo con autorización escrita | Alternativa descartada: puntaje ponderado | Confianza: media.
- Decisión: ENDES queda en nivel 3 y sube a 2 con consentimiento escrito de INEI; conteo: 5 en nivel 1, 0 en 2, 15 en 3, 2 en 4 | Alternativa descartada: nivel 1 amparado en Ley 27806 | Confianza: media.
- Decisión: CC-BY-4.0 solo para código, texto y derivados propios. CHIRPS y ERA5 son compatibles; las bases derivadas de ODC-By deben seguir en ODC-By; de ENDES y ACLED solo se publican salidas transformadas | Alternativa descartada: CC-BY-4.0 sobre toda copia | Confianza: media.

## Riesgos y provisional
- Tamaños de INEI, MEF y espaciales, términos de NASA POWER, SENAMHI y Google, y la compatibilidad requieren revisión legal en la Fase 2.

## Fuentes nuevas
- https://opendatacommons.org/files/2018/02/odc_by_1-0_public_text.txt — texto legal íntegro de ODC-By.
- https://power.larc.nasa.gov/docs/services/api/ — condiciones y límites de NASA POWER.
