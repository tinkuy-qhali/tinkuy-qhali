# ADR 0007 — Remote DVC en Cloudflare R2 y manejo de credenciales

- **Estado:** aceptado (pendiente de que el usuario cree el bucket y el token; se confirma con el primer `dvc push` verificado)
- **Fecha:** 2026-10-16

## Contexto

Los bytes crudos no entran a git (ADR 0002/0003). Hace falta un almacenamiento de trabajo en la nube, direccionable por hash, con egreso barato para que mirrors y usuarios hagan `dvc pull`. El usuario eligió Cloudflare R2 en la Fase 0.2 entre R2, Backblaze B2, OneDrive institucional vía rclone y "solo Zenodo".

## Decisión

1. **Remote por defecto** de DVC: `s3://tinkuy-qhali-raw` con `endpointurl https://<ACCOUNT_ID>.r2.cloudflarestorage.com`, región `auto`. R2 es S3-compatible (DVC lo soporta con `dvc[s3]`), tiene 10 GB gratis y egreso sin costo, lo que favorece mirrors.
2. **Credenciales nunca en git ni en manos del agente**: `.dvc/config` (versionado) solo contiene URL y endpoint; `.dvc/config.local` (gitignored) contiene `access_key_id` y `secret_access_key`, y lo escribe el usuario. El agente no lee ni escribe ese archivo; solo ejecuta `dvc status -c`/`dvc push` y verifica el resultado.
3. **Convención de rutas** en `raw/`: `raw/<source>/<edition>/<module>/<filename>` con `manifest.json` al lado y `manifest.sha256` para `sha256sum -c`.
4. **Caché DVC** en el volumen nombrado `dvc-cache` (fuera de NTFS); `dvc config cache.type reflink,hardlink,copy`.
5. **Puntero** en `tinkuy-qhali-registry/pointers/` por cada archivo, con `locations[kind=dvc-remote]` apuntando al remote y `freeze_level` provisional hasta aplicar la matriz de la Fase 1.

## Alternativas descartadas

- OneDrive EduCorpPERU vía rclone: sin remote nativo, sin direccionamiento por hash, dependencia de una cuenta institucional.
- Solo Zenodo: sin caché de trabajo, límite de 50 GB por registro, no apto para iterar.
- Backblaze B2: equivalente; R2 elegido por egreso gratuito y porque el usuario lo prefirió.

## Pasos que hace el usuario (una vez)

1. Crear cuenta en https://dash.cloudflare.com → R2 Object Storage → *Create bucket* `tinkuy-qhali-raw` (ubicación automática).
2. R2 → *Manage R2 API Tokens* → *Create API token*: permiso **Object Read & Write**, limitado al bucket; copiar *Access Key ID*, *Secret Access Key* y el *Account ID* (visible en la URL del endpoint).
3. En el repo, crear `.dvc/config.local` (gitignored) con:
   ```ini
   ['remote "r2"']
       access_key_id = <ACCESS_KEY_ID>
       secret_access_key = <SECRET_ACCESS_KEY>
   ```
   y decirle al agente el *Account ID* (no es secreto) para que fije `endpointurl` en `.dvc/config`.

## Addendum 2026-10-16 (implementación)

- `dvc init --no-scm`: la libgit2 embebida de DVC falla al renombrar objetos de git sobre el bind-mount de Windows (`PermissionError` en `.git/objects/...lock`), mientras que el CLI de git funciona. DVC no toca git; los archivos `.dvc`, `manifest.json` y `manifest.sha256` dentro de `raw/` se versionan explícitamente (excepciones en `.gitignore`) y se confirman con `git` desde el host o desde el contenedor.
- Caché DVC en `/dvc-cache` (volumen nombrado) en lugar de `.dvc/cache`: `dvc init` rechaza un `.dvc/` preexistente y Docker crea el punto de montaje antes.
- Account ID de R2 registrado en `.dvc/config` (no es secreto): `5cd9171e5332beff49a1752f57985f6a`.
- El puntero del registry añade `dvc_md5` y una ubicación `dvc+r2://files/md5/<2>/<30>` (DVC 3 direcciona la caché por MD5; la identidad del archivo sigue siendo el SHA-256).

## Consecuencias

- `dvc pull` funciona para cualquiera con credenciales de lectura; para acceso público de lectura se evaluará en la Fase 1 (ítem 7) exponer el bucket con dominio público o usar Zenodo como ubicación pública canónica.
- Si R2 dejara de ser viable, el remote cambia sin tocar punteros: la identidad es el hash, no la URL.
