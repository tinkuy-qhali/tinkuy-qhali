# ADR 0014 — Aislamiento de los bytes de nivel 3 en R2 y modelo de credenciales

- **Estado:** propuesto (requiere aprobación del usuario porque reorganiza el bucket y los tokens de R2; hasta entonces rige la regla transitoria de la decisión 6)
- **Fecha:** 2026-10-16
- **Complementa:** ADR 0007 (remote DVC en R2) y ADR 0010 (niveles de congelamiento)
- **Origen:** hallazgo crítico C1 de `docs/reviews/f2-adversarial.md`

## Contexto

El ADR 0007 creó un único bucket R2 (`tinkuy-qhali-raw`) como remote DVC y dejó abierto "exponer el bucket con dominio público"; el plan 3-2-1, el verificador de mirrors, la carta de espejo y `run.sh` (ADR 0011) usaban ese bucket como fuente compartida (`dvc pull` de mirrors, usuarios y CI, token de solo lectura en GitHub Actions, verificación `--deep` que descarga el objeto). Con 15 fuentes en nivel 3 en el mismo bucket, cualquiera de esas vías copiaría bytes de ENDES a un soporte multiusuario (runners de GitHub, máquinas de terceros), lo que la política ANDA del INEI prohíbe sin consentimiento escrito (ADR 0010). Nada en la configuración impedía que una credencial de lectura o un bucket público alcanzara objetos de nivel 3.

## Alternativas

- **Un bucket público para todo:** descartado; viola la política del INEI para nivel 3.
- **Un bucket privado único con credenciales compartidas de lectura:** descartado; es el estado actual y no distingue niveles.
- **Dos remotes DVC (prefijos o buckets separados por nivel) con credenciales distintas:** elegido.

## Decisión

1. **Dos remotes DVC** en `.dvc/config`: `r2-open` para niveles 1 y 2 (prefijo o bucket `tinkuy-qhali-open`) y `r2-restricted` para nivel 3 (prefijo o bucket `tinkuy-qhali-restricted`). Cada `.dvc` de `raw/` declara su remote (`dvc add --to-remote` / `remote:` en el archivo) según el `freeze_level` del manifiesto; un test rechaza un `.dvc` de nivel 3 apuntando a `r2-open`.
2. **Credenciales:** el token de escritura y lectura de `r2-restricted` existe solo en la máquina del usuario (`.dvc/config.local`, nunca en secretos de GitHub ni en la imagen). Para `r2-open` puede existir un token de solo lectura en CI y para mirrors. **Ningún bucket que contenga nivel 3 se expone con dominio público**; la frase correspondiente del ADR 0007 queda sin efecto.
3. **Verificador de mirrors (`verify_mirrors.py`) en CI:** para ubicaciones de nivel 3 solo hace comprobación mínima (`HEAD`/listado del objeto y tamaño) con el token de `r2-open` si el objeto está ahí (no debería) y, si no tiene credenciales, marca `skipped`; **nunca `--deep` sobre nivel 3 fuera de la máquina del usuario**. Un objeto de nivel 3 alcanzable con credenciales de CI o público es `policy-violation` y falla el workflow.
4. **`run.sh`/`run.bat`:** si no hay credenciales de `r2-restricted`, el pipeline cae a `TQ_SYNTHETIC=1` (datos sintéticos) o a los marts de nivel 1–2 disponibles; no pide ni acepta un token compartido.
5. **Carta de espejo e instituciones:** reciben únicamente niveles 1 y 2 (por Zenodo o `r2-open`); el nivel 3 no se ofrece, y una fuente de nivel 3 con consentimiento escrito pasa a nivel 2 por definición (ADR 0010, R5).
6. **Regla transitoria** mientras este ADR no se apruebe e implemente: el bucket actual se trata como `r2-restricted` (contiene ENDES, nivel 3); no se crea ningún token de lectura para CI ni terceros; no se activa dominio público; `mirrors-verify.yml` permanece como placeholder.
7. **Marts fila-nivel de nivel 3** (resuelve M3 de la revisión): no se guardan en DVC ni en R2; son regenerables desde `raw/` con `targets` y viven solo en el volumen local. El ADR 0010, decisión 5, se lee así en adelante.

## Consecuencias

- Pasos del usuario tras aprobar: crear el bucket o prefijo `tinkuy-qhali-open`, un token de solo lectura para CI limitado a él, y mover (o dejar) los objetos de nivel 3 en el actual renombrado como `r2-restricted`; `dvc remote add` de ambos; `dvc push` de ENDES al restringido (ya está, basta renombrar el remote).
- Fase 3: test `tests/test_freeze_remotes.sh` (`.dvc` de nivel 3 → `r2-restricted`), paso `policy-violation` en el verificador, `run.sh` con la caída a sintéticos, `MIRRORS.md` con columna `remote`.
- `docs/preservation/*.md`, ADR 0007 y ADR 0011 se corrigen en el mismo commit que este ADR para no ofrecer `dvc pull` compartido de nivel 3.
- **Provisional:** si una copia transitoria en un runner de GitHub cuenta como "soporte multiusuario" para el INEI no se resuelve: la decisión 3 lo evita por diseño; la revisión legal de la Fase 3 lo anota.
