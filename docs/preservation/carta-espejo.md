---
titulo: Plantilla de carta de invitación a institución espejo (mirror)
estado: borrador
fecha: 2026-10-16
fuentes: [docs/research/07-infraestructura-de-espejos.md, docs/research/06-criterios-de-congelamiento.md, docs/research/_06-anexo-matriz-fuentes.md, docs/adr/0007-remote-dvc-r2.md, raw/inei-endes/2024/1629/manifest.json]
---
# Plantilla de carta/acuerdo de espejo

**[propuesta]** El informe 07 dejó sin cubrir el acuerdo de espejo ("Acuerdo de espejo, Action de verificación y discos fríos se cierran después"). Este texto es un borrador de trabajo, no asesoría legal: las cláusulas requieren revisión legal antes de enviarse (el informe 06 pide revisión legal en la Fase 2). Los campos entre corchetes se completan por cada institución.

## Cómo usar la plantilla

1. Decidir qué niveles recibirá la institución (tabla de la carta): solo nivel 1 y 2. El nivel 3 no se ofrece a instituciones (soporte multiusuario); una fuente de nivel 3 con consentimiento escrito de su productor pasa a nivel 2 (ADR 0010 R5, ADR 0014).
2. Completar los campos `[...]`, revisar y firmar. La carta completa va en la sección A; la versión corta para correo, en la B.
3. Registrar la ubicación en `MIRRORS.md` del registry con `kind: institutional` y la fecha de aceptación.

## A. Carta/acuerdo (versión completa)

**[Ciudad], [fecha]**

**Para:** [Nombre de la persona responsable], [cargo], [institución] 
**De:** Percy Soto-Becerra, [afiliación: UPN / consultora], proyecto tinkuy-qhali

**Asunto:** Invitación a ser institución espejo de archivos de datos de salud de Perú

### 1. Propósito

tinkuy-qhali es un research compendium que referencia archivos de datos abiertos de salud de Perú por su huella `sha256`, de modo que cualquiera pueda verificar que obtiene exactamente los mismos bytes. Para que esos archivos no dependan de un solo proveedor, invitamos a [institución] a conservar una copia y verificarla periódicamente.

### 2. Qué recibe la institución

| Elemento | Detalle |
|---|---|
| Archivos | [lista de `pointer_id`, nombre de archivo, `sha256`, tamaño en bytes] |
| Nivel de congelamiento | [1 público con DOI / 2 restringido con DOI] |
| Volumen total | [N GB] en [N] paquetes |
| Medio de entrega | [enlace Zenodo DOI / `dvc pull` del remote `r2-open` con credenciales de solo lectura / disco físico] |
| Licencia y condiciones de origen | [licencia, `terms_url`, obligación de cita de la fuente] |
| Código y metadatos | punteros JSON y `MIRRORS.md` del repositorio `tinkuy-qhali-registry` |

### 3. Qué se compromete a hacer la institución

1. **Conservar los bytes** sin modificarlos, en almacenamiento con respaldo propio, durante [N años; el informe 07 menciona al menos 20 años para Zenodo como referencia, no como exigencia].
2. **Verificar el hash** `sha256` de cada archivo cada [frecuencia; se sugiere mensual a trimestral] contra el valor del puntero y comunicar cualquier diferencia en un plazo de [N] días hábiles.
3. **Publicar `verified_at`**: declarar por escrito (correo firmado, archivo `attestation.json` firmado o PR al registry) la fecha de cada verificación exitosa y el método usado. Se admite firma con cosign **[provisional]**.
4. **No redistribuir lo de nivel 3**: los archivos de nivel 3 se conservan en custodia, sin acceso de terceros, sin copia a soportes de acceso multiusuario y sin publicación, salvo consentimiento escrito del titular de los datos. Para nivel 1 se respeta la licencia y la cita de origen; para nivel 2 el acceso solo según las condiciones del consentimiento.
5. **Avisar del retiro**: notificar con al menos [60] días de anticipación si deja de ser espejo o debe borrar archivos, y mantener los bytes hasta que otro espejo confirme su copia verificada.
6. **No alterar ni reempaquetar** los archivos; si necesita reempaquetar, conservar el original.
7. **Datos personales**: la institución confirma que no se le entregan datos personales no anonimizados por la fuente y avisa si detecta alguno.

### 4. Qué se compromete a hacer tinkuy-qhali

- Mantener actualizados los punteros, el `sha256` y `MIRRORS.md`, y avisar de cambios de licencia o de fuente.
- Acreditar a la institución como espejo en `MIRRORS.md` y en la documentación [sí / no].
- Notificar si un archivo debe retirarse por orden del titular de los datos.

### 5. Vigencia y término

Vigencia de [N años], renovable. Cualquiera de las partes puede terminar con [60] días de aviso. Al término, la institución elimina los archivos de nivel 3 y de nivel 2 si así lo pide el titular, y conserva los de nivel 1 solo si lo acuerdan ambas partes.

### 6. Contactos

Por la institución: [nombre, correo, teléfono]. Por tinkuy-qhali: [correo del proyecto]. Atención de incidentes: [correo].

**Firma:** ______________________ [institución] &nbsp;&nbsp;&nbsp; ______________________ Percy Soto-Becerra

## B. Versión corta para correo

**Asunto:** Invitación a ser espejo de datos abiertos de salud (tinkuy-qhali)

Estimado/a [nombre]:

Le escribo desde [UPN / consultora] por el proyecto tinkuy-qhali, que preserva y cita archivos de datos abiertos de salud de Perú por su hash `sha256`. Queremos que [institución] sea una de las copias independientes.

Qué recibiría: [N archivos / N GB], nivel [1/2], con su licencia y obligación de cita. Qué le pedimos:

- conservar los bytes sin modificarlos;
- verificar el hash cada [frecuencia] y publicar la fecha (`verified_at`);
- no redistribuir lo marcado como nivel 3;
- avisarnos con [60] días si deja de poder conservarlos.

No incluye datos personales no anonimizados. ¿Podríamos reunirnos [fecha propuesta] para conversarlo? Adjunto la versión completa del acuerdo para revisión legal.

Atentamente,
Percy Soto-Becerra · [afiliación] · [correo]

## Puntos para revisión legal

- Si [institución] puede ser "soporte multiusuario" bajo la política del INEI: el manifiesto ENDES prohíbe copiar a esos soportes sin consentimiento escrito, por eso el nivel 3 no se entrega por defecto.
- Compatibilidad de la cláusula de cita con ODC-By y con la nota de CC-BY-4.0 (solo código, texto y derivados propios; informe 06).
- Responsabilidad ante retiro por mandato del titular.

## Fuentes

- docs/research/07-infraestructura-de-espejos.md (mirrors, Zenodo, cosign, acuerdo de espejo sin cubrir).
- docs/research/06-criterios-de-congelamiento.md y _06-anexo-matriz-fuentes.md (niveles, licencias).
- docs/adr/0007-remote-dvc-r2.md; raw/inei-endes/2024/1629/manifest.json (condiciones INEI).
- https://about.zenodo.org/policies/ ; https://docs.sigstore.dev/cosign/signing/signing_with_blobs/ (informe 07).
- http://webinei.inei.gob.pe/anda_inei/index.php/catalog/817/accesspolicy ; https://opendatacommons.org/licenses/by/1-0/ (informe 06).
