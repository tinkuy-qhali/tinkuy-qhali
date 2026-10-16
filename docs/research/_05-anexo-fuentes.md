# Anexo 05 — Fuentes × términos × legalidad del espejo (consultado 2026-10-16)

Leyenda: **P** público (DOI en Zenodo), **R** restringido (acceso con registro o acuerdo), **I** institucional (solo dentro de la organización), **H** receta de descarga + hash públicos. **[provisional]** = términos no hallados o no leídos en la fuente primaria.

| Fuente | Términos hallados (URL) | Espejo P | Espejo R | Espejo I | Nivel por defecto |
|---|---|---|---|---|---|
| INEI / ENDES 2024 | Política de acceso ANDA: licencia de usuario final, sin comercializar, cita de fuente obligatoria, prohíbe copia a soportes electrónicos multiusuario sin consentimiento escrito (http://webinei.inei.gob.pe/anda_inei/index.php/catalog/817/accesspolicy). Secreto estadístico, D.S. 043-2001-PCM art. 97. La página https://proyectos.inei.gob.pe/microdatos/ no trae términos. La política ANDA está en otro host (webinei) que la descarga (proyectos.inei.gob.pe/iinei/srienaho); su aplicación a esta descarga es inferida **[provisional]**. | No sin consentimiento escrito | Solo con consentimiento escrito | Probable (uso interno, usuario único) **[provisional]** | H |
| datosabiertos.gob.pe (portal) | Sin licencia de portal; licencia por dataset. D.S. 016-2017-PCM sin licencia explícita (https://faolex.fao.org/docs/pdf/per171542.pdf). | Según dataset | Según dataset | Sí | H salvo licencia explícita |
| SUSALUD (RENIPRESS, SIS en el portal) | ODC-By en RENIPRESS (https://www.datosabiertos.gob.pe/dataset/registro-nacional-de-ipress-renipress-superintendencia-nacional-de-salud-susalud) y en SIS (https://www.datosabiertos.gob.pe/dataset/datos-de-atenciones-realizadas-los-asegurados-sis). Portal propio de SUSALUD inaccesible hoy **[provisional]**. | Sí, con atribución (ODC-By) | Sí | Sí | P para datasets ODC-By |
| HIS-MINSA | MINSA-IPRESS: "License Not Specified" (https://www.datosabiertos.gob.pe/dataset/minsa-ipress). Tablas maestras HISMINSA: ODC-By solo según un buscador, no verificado en la página **[provisional]**. | No hasta verificar | Sí tras revisar | Sí | H |
| MEF Consulta Amigable / SIAF | Portal https://datosabiertos.mef.gob.pe/ sin aviso ni licencia; comunicado MEF de libre disposición no leído **[provisional]**. | No hasta verificar | Sí | Sí | H |
| SENAMHI | Página de condiciones renderizada por JavaScript, ilegible (https://www.senamhi.gob.pe/?p=terminos_condiciones). Un tercero reporta uso libre con cita de SENAMHI como titular **[no oficial]** (https://pypi.org/project/phd-scraper/) **[provisional]**. | No hasta verificar | Sí | Sí | H |
| Copernicus / ERA5 | CC-BY (https://cds.climate.copernicus.eu/datasets/reanalysis-era5-single-levels?tab=overview); cambio de licencia 2025-07-02 (https://forum.ecmwf.int/t/cc-by-licence-to-replace-licence-to-use-copernicus-products-on-02-july-2025/13464). Citar DOI de cada dataset. | Sí, con atribución | Sí | Sí | P |
| CHIRPS | Dominio público según CHC (https://www.chc.ucsb.edu/data/chirps); la página "Appropriate Use" no se leyó **[provisional]**. | Sí (cita recomendada) | Sí | Sí | P |
| Defensoría del Pueblo (conflictos) | No se halló aviso de reutilización. Ley 27806 presume pública la información pero no licencia **[provisional]**. | No hasta verificar | Sí | Sí | H |
| ACLED | EULA y Content Usage Terms, actualizados 2025-07-08: sin redistribución salvo material transformador, sin acceso directo de terceros, restricciones sobre IA/ML (https://acleddata.com/eula, https://acleddata.com/contentusage). Licencias por tipo de usuario. | No | No (prohibido el acceso directo a terceros) | Solo con licencia propia de la institución | H (o solo citar) |
| GDELT | Uso sin restricciones; permite redistribuir, alojar y espejar con cita y enlace (https://www.gdeltproject.org/about.html). | Sí, con cita y enlace | Sí | Sí | P |
| Google COVID-19 Mobility Reports | Exige aceptar los Terms of Service de Google; sin actualizar desde 2022-10-15; datos históricos disponibles (https://www.google.com/covid19/mobility/). ToS no leídos **[provisional]**. | No hasta leer ToS | Posible | Sí | H |

## Marco jurídico (resumen)

- Ley 29733: la salud es dato sensible; estudios epidemiológicos con disociación y datos anonimizados exentos de consentimiento (arts. 2, 14.6, 14.8) (https://www.smv.gob.pe/Uploads/Ley_29733_vigente_2025.pdf) **[no oficial]**. La copia de la ley en el SMV anota el D.S. 016-2024-JUS como reglamento vigente y el D.S. 003-2013-JUS como derogado; la fecha de vigencia (2025-03-30) viene de https://www.cuatrecasas.com/es/latam/propiedad-intelectual/art/nuevo-reglamento-ley-de-proteccion-datos-personales **[no oficial]**.
- Ley 27806 (TUO, D.S. 021-2019-JUS): presunción de publicidad (art. 3), excepción de salud personal (art. 17.5), tasa de reproducción (art. 20). Es acceso, no licencia (https://www2.congreso.gob.pe/sicr/cendocbib/con5_uibd.nsf/DE0722775AABAAC9052586DB001D51FA/$FILE/TUO-LEY27806.pdf) **[no oficial]**.
- Decisión 351, art. 28: "Las bases de datos son protegidas siempre que la selección o disposición de las materias constituyan una creación intelectual"; la protección no se extiende a los datos (texto citado en la Interpretación Prejudicial 10-IP-99, https://www.comunidadandina.org/DocOficialesFiles/Procesos/10-IP-99.doc).
- D.Leg. 822, art. 78, misma regla; art. 9 excluye hechos y datos simples (https://www.wipo.int/wipolex/edocs/lexdocs/laws/es/pe/pe077es.html) **[no oficial]**. No se encontró derecho sui generis en lo leído (aprox. un tercio del texto); la vía residual sería competencia desleal **[provisional]**.

## Contenido mínimo de un manifiesto de espejo

1. Fuente, URL de origen y entidad titular.
2. Fecha y hora de descarga, nombre de archivo, tamaño y sha256.
3. URL de los términos y copia (o hash de captura) de su texto vigente en la fecha de la copia.
4. Licencia efectiva y condiciones de reutilización (atribución, no comercialización, cita exigida).
5. Aviso de no afiliación y de que el original manda ante discrepancias.
6. Nivel de congelamiento (P, R, I o H) y justificación.
7. Estado de confidencialidad (secreto estadístico, datos personales, anonimización aplicada).
8. Contacto y procedimiento de retiro.
