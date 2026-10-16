---
titulo: Especificación del verificador periódico de mirrors
estado: borrador
fecha: 2026-10-16
fuentes: [docs/research/07-infraestructura-de-espejos.md, docs/research/_07-anexo-plataformas.md, docs/research/26-lo-que-falta.md, docs/adr/0007-remote-dvc-r2.md, raw/inei-endes/2024/1629/manifest.json, .github/workflows/mirrors-verify.yml]
---
# Verificador periódico de mirrors

Especificación de `tinkuy-qhali-registry/tools/verify_mirrors.py`, a implementar en la Fase 3. Hoy solo existe el placeholder `.github/workflows/mirrors-verify.yml` (mensual, cron `41 7 1 * *`, permisos `contents: read`, imprime "No mirrors declared yet"). Todo el diseño es **[propuesta]** salvo lo citado de los informes. El esquema exacto de los punteros no está en este repo; los campos de `locations[]` abajo son **[provisional]** hasta ver el registry.

## Objetivo

Comprobar, para cada archivo, que cada ubicación declarada todavía entrega los bytes con el `sha256` del puntero, y dejar constancia fechada. El verificador nunca toma una ubicación como verdad sin hash: la identidad es el `sha256` (ADR 0007).

## Entradas

| Entrada | Contenido usado |
|---|---|
| `pointers/*.json` | `pointer_id`, `sha256`, `size_bytes`, `freeze_level`, `locations[]` con `kind`, `url`, `verified_at`; para DVC, `dvc_md5` (ADR 0007, addendum) |
| `MIRRORS.md` | tabla `sha256`, `pointer_id`, nivel, `kind`, URL, `verified_at`, firma; debe coincidir con los punteros (fuente única: los punteros, `MIRRORS.md` se genera) |
| Entorno | `DVC_*`/credenciales R2 de solo lectura como secretos del workflow; token de Zenodo solo si hay registros restringidos (nivel 2) |

Ejemplo real de puntero de partida: ENDES 1629 (`sha256` 1a76f981...c799, 5 184 994 bytes, nivel 3 confirmado, `origin_url` en proyectos.inei.gob.pe).

## Comprobaciones por `location.kind`

| `kind` | Comprobación mínima (siempre) | Comprobación profunda (`--deep`) | Qué prueba |
|---|---|---|---|
| `origin` | `HEAD` a `url`: código 2xx y `Content-Length` igual a `size_bytes` | descargar a directorio temporal y calcular `sha256` | que la fuente sigue publicando el mismo archivo |
| `dvc-remote` | `dvc status -c` o `ls`/`HEAD` del objeto `files/md5/<2>/<30>` (`dvc_md5`) y tamaño igual a `size_bytes` | `dvc pull` del objeto y `sha256` | que R2 conserva el objeto; DVC 3 direcciona por MD5, así que sin `--deep` el `sha256` no se prueba |
| `zenodo` | `GET` de la API del registro: archivo presente, tamaño igual y checksum publicado | descargar y calcular `sha256` | que el registro sigue vigente y no está revocado ni con tombstone |
| `institutional` | declaración firmada vigente (no más antigua que la cadencia del acuerdo) | pedir al custodio el hash de un archivo elegido al azar (desafío) | que la institución verificó; no se puede automatizar la descarga |
| `cold-storage` | declaración firmada del responsable con fecha y comando usado (`sha256sum -c`) | revisión manual con el disco conectado | que el disco frío sigue íntegro |

Notas por tipo:

- **origin**: el portal del INEI rechazó una conexión durante la investigación (informe 06); un fallo aislado no significa retiro. Se marca `unavailable` solo tras 3 ejecuciones consecutivas fallidas. Respetar `terms_url`: la descarga profunda es para verificar, no para redistribuir.
- **zenodo**: el informe 07 no verifica qué algoritmo de checksum expone la API; suele publicarse MD5, no `sha256` **[provisional]**. Por eso la comprobación mínima coteja tamaño y checksum publicado, y el `sha256` exige `--deep` o un `manifest.sha256` dentro del paquete. Nivel 3 no tiene ubicación Zenodo; si aparece una, es un error de política.
- **dvc-remote**: las credenciales las pone el usuario (ADR 0007); en CI se usa un token de solo lectura limitado al bucket **[propuesta]**.
- **institutional / cold-storage**: la declaración es un `attestation.json` con `pointer_id`, `sha256`, `verified_at`, método y firma; se acepta como evidencia, no como prueba.

## Resultados por ubicación

Estados: `ok` (hash o tamaño coinciden), `mismatch` (el hash difiere: crítico), `unavailable` (no responde), `stale` (declaración más antigua que la cadencia), `skipped` (profunda no pedida, mínima inconcluyente), `policy-violation` (p. ej. bytes de nivel 3 en ubicación pública).

Reglas de salud por archivo: al menos 2 ubicaciones `ok` es saludable; 1 es advertencia; 0 es error. En nivel 3 el mínimo es R2 y disco frío (ver `plan-3-2-1.md`).

## Salida

1. **`verified_at` actualizado por PR**: si una ubicación pasa a `ok`, el workflow abre un PR contra el registry que actualiza `verified_at` en el puntero y regenera `MIRRORS.md`. Nunca hace push directo a `main`. Requiere ampliar los permisos del workflow a `contents: write` y `pull-requests: write` (hoy `contents: read`).
2. **Informe Markdown** `reports/mirrors-AAAA-MM.md` (y resumen del job): tabla `pointer_id` × ubicación × estado, fecha, versión de la herramienta y lista de acciones. Se adjunta como artefacto del workflow.
3. **Código de salida**:

| Código | Significado |
|---|---|
| 0 | todo `ok` o solo `stale`/`skipped` informativos |
| 1 | al menos un `mismatch` o `policy-violation` (incidente, ver plan 3-2-1) |
| 2 | ubicaciones `unavailable` o archivos con menos de 2 ubicaciones sanas, sin `mismatch` |
| 3 | entrada inválida (puntero malformado, `MIRRORS.md` desalineado) |

Un `mismatch` abre además un issue con etiqueta `incidente-mirror` **[propuesta]**.

## Cadencia

- Mensual en el workflow `mirrors-verify.yml` (cron `41 7 1 * *`, ya existe), con `workflow_dispatch` para correrlo a demanda tras cada ingesta nueva.
- Mensual: comprobación mínima de todos los `kind`. Trimestral: `--deep` sobre una muestra aleatoria **[propuesta]**; anual: `--deep` completo junto con el simulacro de restauración.
- El job de GitHub Actions solo ve lo que puede alcanzar: `cold-storage` e `institutional` se verifican por declaración y se marcan `stale` si vencen.
- Con la primera ubicación declarada se reemplaza el paso placeholder por `python tools/verify_mirrors.py --report ...` en el registry; el workflow del repo principal puede invocarlo vía checkout del registry.

## Firma de checksums

- Se firman `MIRRORS.md` y, por cada release, el archivo `SHA256SUMS` con `cosign sign-blob --bundle` (informe 07); el bundle se publica junto al archivo. La verificación usa `cosign verify-blob --bundle` **[provisional]**: el informe solo cita la firma de blobs, no la política de identidad.
- El verificador comprueba la firma de `MIRRORS.md` antes de confiar en él; una firma inválida da código 3.
- Firma sin llave (OIDC de GitHub Actions) frente a llave propia: sin decidir **[provisional]**. El informe 26 también propone firmar SBOM e imagen con la misma herramienta.
- Una firma de cosign no sustituye la verificación de hash: prueba quién publicó la lista, no que los bytes sigan íntegros.

## Pruebas de aceptación sugeridas (Fase 3)

- Puntero de ENDES 1629 con origen caído simulado: código 2 sin cambiar `verified_at`.
- Archivo alterado en una copia local: código 1 y el informe lo lista como `mismatch`.
- Nivel 3 con una ubicación `zenodo`: `policy-violation`.
- `MIRRORS.md` editado a mano: código 3.

## Fuentes

- docs/research/07-infraestructura-de-espejos.md y _07-anexo-plataformas.md (Zenodo, `dvc import-url`, cosign, resolver por `sha256`).
- docs/research/26-lo-que-falta.md y _26-anexo-tabla.md (DR, cosign para SBOM).
- docs/adr/0007-remote-dvc-r2.md (rutas DVC, `dvc_md5`, credenciales); raw/inei-endes/2024/1629/manifest.json; .github/workflows/mirrors-verify.yml.
- https://doc.dvc.org/command-reference/import-url ; https://docs.sigstore.dev/cosign/signing/signing_with_blobs/ ; https://help.zenodo.org/docs/deposit/about-records/ (informe 07).
- https://developers.cloudflare.com/r2/reference/durability/ (informe 26).
