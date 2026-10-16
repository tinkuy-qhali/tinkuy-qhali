---
item: 7
titulo: Infraestructura de espejos
modelo: sonnet
esfuerzo: medium
fecha: 2026-10-16
estado: borrador
---
# 07 — Infraestructura de espejos

## Pregunta
Qué plataformas y mecanismos permiten recuperar un archivo dado un hash y una lista de mirrors. Tabla en `_07-anexo-plataformas.md`.

## Hallazgos
- Zenodo: 50 GB y 100 archivos por registro; ampliación puntual hasta 200 GB bajo petición (https://help.zenodo.org/docs/deposit/manage-files/, https://help.zenodo.org/docs/deposit/manage-files/quota-increase, 2026-10-16).
- Zenodo conserva mientras exista el repositorio (CERN, al menos 20 años); no borra: revoca, retira con tombstone o retracta; admite embargo y acceso restringido (https://about.zenodo.org/policies/, 2026-10-16).
- Zenodo: cada versión es un registro con DOI propio; archivos no editables (https://help.zenodo.org/docs/deposit/about-records/, 2026-10-16). Un DOI por release de GitHub (https://docs.github.com/articles/referencing-and-citing-content, 2026-10-16). El concept DOI quedó sin fuente oficial **[provisional]**.
- Dataverse propio exige Java 21, Payara, PostgreSQL 17 y Solr 9.8 (https://guides.dataverse.org/en/latest/installation/prerequisites.html, 2026-10-16). UPN usa DSpace, sin Dataverse hallado (https://repositorio.upn.edu.pe/static/documents/Protocolo.pdf, 2026-10-16).
- ALICIA (CONCYTEC) cosecha repositorios; no hallé servicio peruano de datos tipo Dataverse (https://portal.concytec.gob.pe/images/publicaciones/guias-doc/guia_ALICIA_version_2.0.pdf, 2026-10-16).
- OSF: 5 GB privado, 50 GB público por proyecto (https://help.osf.io/article/137-osf-storage-caps, 2026-10-16).
- Hugging Face: privado 100 GB gratis, archivo máximo 500 GB; gated con aprobación manual (https://huggingface.co/docs/hub/storage-limits, https://huggingface.co/docs/hub/datasets-gated, 2026-10-16).
- Software Heritage: SWHID es hash de contenido; Save Code Now se pide por web o API (https://www.swhid.org/faq, https://docs.softwareheritage.org/devel/apidoc/swh.web.save_code_now.api_views.html, 2026-10-16).
- Internet Archive recomienda ítems de menos de 10 000 archivos y menos de 1 TB (https://help.archive.org/help/uploading-troubleshooting/, 2026-10-16).
- LOCKSS: copias múltiples con reparación entre cachés; CLOCKSS es archivo oscuro de publicaciones (https://www.digitalpreservation.gov/partners/lockss.html, 2026-10-16); aceptación de datos de estudio **[provisional]**.
- `dvc import-url --no-download` guarda hash/ETag y `dvc pull` falla si no coincide (https://doc.dvc.org/command-reference/import-url, 2026-10-16); git-annex usa claves SHA256, `whereis` y `numcopies` (https://git-annex.branchable.com/walkthrough/, 2026-10-16); ORAS sube artefactos a registros OCI (https://oras.land/docs/, 2026-10-16); `pins` versiona sin hash documentado (https://pins.rstudio.com/, 2026-10-16).
- cosign firma blobs con `--bundle` (https://docs.sigstore.dev/cosign/signing/signing_with_blobs/, 2026-10-16). Regla 3-2-1 y Action de verificación periódica sin fuente oficial **[provisional]**.

## Decisión propuesta
- Decisión: niveles: R2 (operativo), Zenodo (citable), Software Heritage (código), Hugging Face gated solo si hay acceso controlado, disco frío o NAS UPN como tercera copia | Alternativa descartada: Dataverse propio en UPN | Confianza: media.
- Decisión: resolver por `sha256` con `MIRRORS.md` (hash, URLs, firma cosign) y un script que pruebe mirrors en orden y verifique el hash | Alternativa descartada: git-annex u ORAS como base | Confianza: media.

## Riesgos y provisional
- El límite de 100 archivos obliga a empaquetar; las cuotas cambian. Acuerdo de espejo, Action de verificación y discos fríos se cierran después.

## Fuentes nuevas
- https://help.zenodo.org/docs/github/ — integración oficial y concept DOI, sin verificar.
- https://docs.softwareheritage.org/user/faq/ — FAQ oficial de archivado y Save Code Now.
