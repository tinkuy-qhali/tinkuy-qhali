---
titulo: Plan de preservación 3-2-1 y recuperación ante pérdidas
estado: borrador
fecha: 2026-10-16
fuentes: [docs/research/07-infraestructura-de-espejos.md, docs/research/_07-anexo-plataformas.md, docs/research/06-criterios-de-congelamiento.md, docs/research/_06-anexo-matriz-fuentes.md, docs/research/26-lo-que-falta.md, docs/research/_26-anexo-tabla.md, docs/adr/0007-remote-dvc-r2.md, raw/inei-endes/2024/1629/manifest.json]
---
# Plan de preservación 3-2-1 y recuperación

Documento operativo derivado de los informes 06, 07 y 26 y del ADR 0007. Lo que no tenga fuente en esos documentos va marcado **[provisional]** (dato sin verificar) o **[propuesta]** (decisión de diseño de este borrador, pendiente de aceptación). La regla 3-2-1 misma y los objetivos RPO/RTO son **[provisional]** según los informes 07 y 26.

## Principios

- La identidad de un archivo es su `sha256`, no su URL (ADR 0007, consecuencias). Cambiar de remote o de mirror no toca los punteros.
- `raw/` es un espejo byte a byte; nunca se edita (`never_edit` en el manifiesto).
- Niveles de congelamiento (informe 06): 1 espejo público con DOI; 2 restringido con DOI; 3 receta y hash públicos, bytes en almacenamiento privado; 4 no espejar.
- Meta: 3 copias de los bytes (R2, Zenodo, física) en 2 tipos de soporte (nube y disco), 1 fuera del proveedor principal **[provisional]**. Donde el nivel impide la copia en Zenodo quedan 2 copias de bytes más la receta (ver "Límite honesto del nivel 3").

## Las tres copias

| Copia | Plataforma | Papel | Quién la escribe | Fuente |
|---|---|---|---|---|
| 1. Operativa | Cloudflare R2, dos remotes DVC: `r2-open` (niveles 1–2) y `r2-restricted` (nivel 3) (ADR 0014) | trabajo diario del usuario; `dvc pull` de mirrors y CI solo sobre `r2-open` | `dvc push` con credenciales en `.dvc/config.local`; el token de `r2-restricted` existe solo en la máquina del usuario | ADR 0007, 0014 |
| 2. Citable | Zenodo (integración GitHub, un DOI por versión); solo niveles 1 y 2 | cita, permanencia, acceso público o restringido | release de GitHub o depósito manual | informes 06, 07 |
| 3. Física | disco frío (preferente) o NAS UPN | recuperación si caen R2 y Zenodo | el usuario, copia manual con verificación de hash | informe 07 |

Complementos que no son copia de datos: GitHub (código, punteros, `MIRRORS.md`); Software Heritage para el código vía Save Code Now (informe 07); el repo `tinkuy-qhali-registry` con un puntero por `sha256`.

Estado actual: no hay backups físicos; la copia 3 está por crear. El ADR 0007 deja el remote R2 "pendiente de confirmar con el primer `dvc push` verificado".

## Qué va en cada copia según el nivel

| Nivel | Copia 1: R2 | Copia 2: Zenodo | Copia 3: física | Registry (git) |
|---|---|---|---|---|
| 1 público con DOI | bytes (recorte a Perú si pesa más de 10 GB) | bytes, acceso abierto | bytes, disco frío o NAS UPN | puntero, hash, DOI |
| 2 restringido con DOI | bytes | bytes con acceso restringido, solo con autorización escrita (regla R5) | disco frío; NAS solo si la autorización lo permite **[propuesta]** | puntero, hash, DOI |
| 3 receta + hash | bytes en `r2-restricted` (solo el usuario; nunca `dvc pull` compartido ni dominio público, ADR 0014) | nada | disco frío de un único usuario **[propuesta]**; NAS UPN no (ver abajo) | receta, `sha256`, `origin_url`, `terms_url` |
| 4 no espejar | nada | nada | nada | solo nota de exclusión, sin bytes |

Hoy hay 5 fuentes en nivel 1, 0 en 2, 15 en 3 y 2 en 4 (informe 06). ENDES 1629 (5 184 994 bytes, `sha256` 1a76f981...c799) está en nivel 3 confirmado por decisión del usuario; sube a 2 solo con consentimiento escrito del INEI.

### Límite honesto del nivel 3

- Con 15 de 22 fuentes en nivel 3, la mayoría tendrá 2 copias de bytes (R2 restringido y disco frío personal) más el origen mientras exista: es 2-2-1, no 3-2-1, por diseño; la tercera "copia" es la receta reproducible (así lo redacta también el ADR 0010).
- Contradicción a resolver: el informe 07 ofrece "disco frío o NAS UPN" sin distinguir nivel, pero la política del INEI prohíbe copiar a soportes de acceso multiusuario sin consentimiento escrito (manifiesto ENDES). Un NAS institucional puede serlo. Hasta tener revisión legal, la regla es disco frío personal para nivel 3 **[propuesta]**.

## Cuotas y empaquetado

| Plataforma | Límite verificado (informe 07 y ADR 0007) | Consecuencia práctica |
|---|---|---|
| Zenodo | 50 GB y 100 archivos por registro; hasta 200 GB bajo petición | empaquetar (tar por fuente y edición); un registro por versión |
| R2 | 10 GB gratis, egreso sin costo (ADR 0007) | ERA5 global (~36 GB por variable-año, informe 06) exige recorte a Perú o plan de pago **[provisional]** |
| Hugging Face | privado 100 GB, archivo máx. 500 GB, gated manual | solo si se necesita acceso controlado |
| OSF | 5 GB privado, 50 GB público | no usar como espejo principal |
| Internet Archive | menos de 10 000 archivos y 1 TB por ítem (recomendado) | opción pública futura; no para nivel 3 |

Ejemplos: CHIRPS mensual (~14 MiB/mes, ~7,6 GB 1981-2026) son unos 550 archivos, más de 5 veces el límite de 100: empaquetar por año. GDELT diario son 365 zips al año: empaquetar por mes o año. Cada paquete lleva un `manifest.sha256` con el hash de cada archivo interno **[propuesta]**.

## Verificación periódica

- Hash contra `MIRRORS.md` (registry): cada ubicación se comprueba según su `location.kind`; el detalle está en `verificacion-mirrors.md`.
- Cadencia **[propuesta]**: mensual automática (workflow `mirrors-verify.yml`, hoy placeholder con cron `41 7 1 * *`); disco frío cada 6 meses con `sha256sum -c` y declaración firmada; tras cada ingesta nueva, verificación inmediata de las tres copias.
- Un hash que no coincide es incidente: se aísla la ubicación, se restaura desde otra copia con hash válido y se anota en la bitácora.

## Escenarios de pérdida

Objetivos globales: RPO 7 días, RTO 48 horas **[provisional]** (informe 26: propuesta sin fuente, se ensaya en Ronda 2). RPO es aquí la ventana máxima de trabajo o ingesta sin copia independiente.

| Escenario | RPO | RTO | Procedimiento de restauración |
|---|---|---|---|
| Se pierde o daña la laptop | 7 días (trabajo sin push; `git push` y `dvc push` al menos semanales) | 48 h | 1) Clonar repo y registry. 2) Recrear `.dvc/config.local` (token R2 nuevo si hace falta). 3) `dvc pull`. 4) `sha256sum -c` contra `manifest.sha256`. 5) Levantar la imagen y `renv::restore()`. |
| Se pierde R2 (bucket borrado, cuenta suspendida, token comprometido) | 0 en niveles 1-2 (Zenodo); hasta 7 días en nivel 3 (desde la última copia al disco) **[propuesta]** | 48 h | 1) Revocar tokens. 2) Crear bucket nuevo. 3) Niveles 1-2: bajar de Zenodo y verificar `sha256`; nivel 3: copiar desde disco frío o caché DVC local. 4) `dvc push`. 5) Ajustar `endpointurl` en `.dvc/config`; los punteros no cambian (ADR 0007). 6) Actualizar `verified_at`. |
| Se pierde GitHub (repo, cuenta u organización) | 7 días (último clon local o release en Zenodo y Software Heritage) | 48 h | 1) Recrear repo desde clon local; si no hay, desde el release en Zenodo y Software Heritage (solo código). 2) Restaurar registry y `MIRRORS.md`. 3) Reconfigurar la integración Zenodo-GitHub; puede generar un concept DOI nuevo, sin fuente oficial **[provisional]**. 4) Revisar `CITATION.cff`. |
| Zenodo retira, retracta o pierde un registro | 0 (los bytes siguen en R2 y disco) | 48 h | Zenodo no borra: revoca o deja tombstone (informe 07). 1) Verificar bytes en R2. 2) Crear versión nueva con otro DOI. 3) Actualizar punteros y `MIRRORS.md`; conservar el DOI antiguo como histórico. |
| INEI retira el archivo (ENDES, nivel 3) | 0 para lo ya capturado; lo no capturado no se recupera | no aplica: no se pierde nada capturado | 1) Marcar `origin` como `unavailable` tras 3 verificaciones fallidas consecutivas **[propuesta]** (el portal ya rechazó conexiones, informe 06). 2) Servir bytes solo desde R2 y disco, sin redistribuir (nivel 3). 3) Citar con `origin_url` y fecha de captura. 4) Pedir al INEI consentimiento escrito para subir a nivel 2. |

## Simulacro de restauración

- Cadencia **[propuesta]**: trimestral parcial y anual completo; el informe 26 ubica el simulacro en la Ronda 2.
- Parcial: en un directorio vacío, `dvc pull` de ENDES 1629 (5,2 MB) desde R2, comprobar `sha256` contra el manifiesto y medir el tiempo.
- Completo: simular la pérdida de R2 (bucket de prueba vacío) y restaurar niveles 1-3 desde Zenodo y disco frío; medir contra el RTO de 48 h y anotar en la bitácora.
- Éxito: todos los `sha256` coinciden y el tiempo no excede el RTO. Si falla, abrir un issue y corregir este documento.

## Qué nunca se preserva

- Datos personales no anonimizados por la fuente (Ley 29733), por ejemplo INCOR (nivel 4); SINADEF solo se preserva (nivel 3) si la fuente publica registros anonimizados; si contiene datos personales pasa a nivel 4 (ADR 0010, regla R1 evaluada primero).
- Nivel 4: ACLED (el EULA prohíbe redistribuir; solo se publican salidas transformadoras) y toda fuente sin licencia verificable con riesgo de datos personales.
- Credenciales, tokens de R2 o Zenodo y `.dvc/config.local`: nunca en git ni en ninguna copia (ADR 0007).
- Bytes de nivel 3 en Zenodo, Hugging Face público o cualquier mirror abierto.

## Contradicciones y huecos entre informes

1. 06 pone ERA5 en nivel 1 con recorte a Perú; 07 y el ADR 0007 solo cubren 10 GB en R2 y 50 GB por registro en Zenodo. Nadie calculó el tamaño del recorte **[provisional]**.
2. 06 acota por tamaño total (10 GB) pero no por número de archivos; 07 limita a 100 archivos por registro. CHIRPS y GDELT exigen empaquetado.
3. 07 admite NAS UPN como tercera copia sin distinguir nivel; las condiciones de ENDES (nivel 3) lo impiden sin consentimiento.
4. 06 define nivel 2 como restringido con DOI; 07 prevé Zenodo restringido y Hugging Face gated, pero no verifica que eso cumpla el consentimiento del INEI.

## Fuentes

- docs/research/07-infraestructura-de-espejos.md y _07-anexo-plataformas.md (cuotas, Zenodo, cosign, 3-2-1 provisional).
- docs/research/06-criterios-de-congelamiento.md y _06-anexo-matriz-fuentes.md (niveles, reglas R1-R5, conteo).
- docs/research/26-lo-que-falta.md y _26-anexo-tabla.md (DR: RPO 7 días, RTO 48 h).
- docs/adr/0007-remote-dvc-r2.md; raw/inei-endes/2024/1629/manifest.json.
- https://help.zenodo.org/docs/deposit/manage-files/ ; https://about.zenodo.org/policies/ ; https://help.zenodo.org/docs/deposit/about-records/ (informe 07).
- https://developers.cloudflare.com/r2/reference/durability/ ; https://about.zenodo.org/infrastructure/ (informe 26).
- https://help.osf.io/article/137-osf-storage-caps ; https://huggingface.co/docs/hub/storage-limits ; https://help.archive.org/help/uploading-troubleshooting/ (informe 07).
- http://webinei.inei.gob.pe/anda_inei/index.php/catalog/817/accesspolicy (manifiesto ENDES e informe 06).
