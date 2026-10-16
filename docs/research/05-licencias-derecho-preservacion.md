---
item: 5
titulo: Licencias, derecho y preservación
modelo: sonnet
esfuerzo: high
fecha: 2026-10-16
estado: borrador
---
# 05 — Licencias, derecho y preservación

## Pregunta
¿Qué términos rigen cada fuente y es legal mantener espejos públicos, restringidos o institucionales? ¿Qué debe declarar un espejo? Ver `_05-anexo-fuentes.md`.

## Hallazgos
- INEI: el manifiesto queda refutado. La política de acceso de ENDES 2024 exige citar la fuente y prohíbe copiar a soportes electrónicos multiusuario sin consentimiento escrito del INEI (http://webinei.inei.gob.pe/anda_inei/index.php/catalog/817/accesspolicy, 2026-10-16); el portal no trae términos (https://proyectos.inei.gob.pe/microdatos/, 2026-10-16).
- datosabiertos.gob.pe no declara licencia de portal; la fija cada dataset: ODC-By en RENIPRESS (SUSALUD), "License Not Specified" en MINSA-IPRESS (https://www.datosabiertos.gob.pe/dataset/registro-nacional-de-ipress-renipress-superintendencia-nacional-de-salud-susalud, 2026-10-16; https://www.datosabiertos.gob.pe/dataset/minsa-ipress, 2026-10-16).
- El D.S. 016-2017-PCM promueve reutilización sin fijar licencia **[no oficial]** (https://faolex.fao.org/docs/pdf/per171542.pdf, 2026-10-16).
- ERA5 es CC-BY (https://cds.climate.copernicus.eu/datasets/reanalysis-era5-single-levels?tab=overview, 2026-10-16), que reemplazó la Licence to use Copernicus el 2025-07-02 (https://forum.ecmwf.int/t/cc-by-licence-to-replace-licence-to-use-copernicus-products-on-02-july-2025/13464, 2026-10-16). CHIRPS está en dominio público (https://www.chc.ucsb.edu/data/chirps, 2026-10-16). GDELT permite espejar con cita y enlace (https://www.gdeltproject.org/about.html, 2026-10-16).
- ACLED: el EULA prohíbe redistribuir salvo material transformador (https://acleddata.com/eula, 2026-10-16). Google Mobility remite a sus Terms of Service; discontinuado el 2022-10-15 (https://www.google.com/covid19/mobility/, 2026-10-16).
- Ley 29733: salud es dato sensible; estudios epidemiológicos con disociación y datos anonimizados no requieren consentimiento (arts. 2, 14.6, 14.8) **[no oficial]** (https://www.smv.gob.pe/Uploads/Ley_29733_vigente_2025.pdf, 2026-10-16). Su reglamento D.S. 016-2024-JUS rige desde 2025-03-30 **[no oficial]** (https://www.cuatrecasas.com/es/latam/propiedad-intelectual/art/nuevo-reglamento-ley-de-proteccion-datos-personales, 2026-10-16).
- Ley 27806: presume pública la información estatal (art. 3), exceptúa la salud personal (art. 17.5) y no otorga licencia **[no oficial]** (https://www2.congreso.gob.pe/sicr/cendocbib/con5_uibd.nsf/DE0722775AABAAC9052586DB001D51FA/$FILE/TUO-LEY27806.pdf, 2026-10-16).
- Decisión 351 (art. 28) y D.Leg. 822 (art. 78) protegen bases de datos solo por originalidad de selección o disposición, no los datos; no hay derecho sui generis (https://www.comunidadandina.org/DocOficialesFiles/Procesos/10-IP-99.doc, 2026-10-16; **[no oficial]** https://www.wipo.int/wipolex/edocs/lexdocs/laws/es/pe/pe077es.html, 2026-10-16).
- MEF, SENAMHI, Defensoría y HIS-MINSA: términos no localizados **[provisional]**.

## Decisión propuesta
- Decisión: espejo público solo de CHIRPS, GDELT, ERA5 y datasets ODC-By, con atribución; ENDES y ACLED, receta + hash y espejo restringido o institucional solo con autorización escrita; el resto, receta + hash | Alternativa descartada: espejo público de ENDES amparado en Ley 27806 | Confianza: media.
- Decisión: todo espejo declara origen, fecha, sha256, términos vigentes (URL y copia), licencia efectiva, no afiliación, atribución y contacto de retiro | Alternativa descartada: manifiesto solo con hash | Confianza: alta.

## Riesgos y provisional
- Normas leídas en copias (gob.pe bloqueó el acceso) y D.Leg. 822 parcialmente. Cierran la matriz del ítem 6 y revisión legal; corregir `terms_url` del manifiesto ENDES y pedir consentimiento a infoinei@inei.gob.pe.

## Fuentes nuevas
- https://www.gob.pe/institucion/anpd/normas-legales/6554453-16-2024-jus — texto oficial del D.S. 016-2024-JUS (vigencia, anonimización).
- https://acleddata.com/contentusage — restricciones de ACLED sobre IA, relevantes para un proyecto agéntico.
