# ADR 0010 — Licencias de derivados y niveles de congelamiento aplicados por fuente

- **Estado:** aceptado (la revisión legal humana de los puntos marcados queda programada para antes de la primera release pública, Fase 3)
- **Fecha:** 2026-10-16
- **Complementa:** ADR 0004 (precisa la condición "CC-BY-4.0 condicionada") y ADR 0007 (R2 como copia operativa)
- **Fuente:** Fase 1, informes 05 (+ anexo fuentes), 06 (+ anexo matriz), 07 (+ anexo plataformas); decisión del usuario del 2026-10-16 sobre ENDES

## Contexto

El ADR 0004 dejó CC-BY-4.0 para derivados "condicionada al nivel de congelamiento" sin fijar niveles por fuente. La investigación verificó los términos de 22 fuentes (`docs/research/_05-anexo-fuentes.md`) y aplicó una matriz de cinco ejes (`docs/research/_06-anexo-matriz-fuentes.md`). Hallazgo decisivo: la política de acceso de ENDES 2024 en el catálogo ANDA del INEI (http://webinei.inei.gob.pe/anda_inei/index.php/catalog/817/accesspolicy, 2026-10-16) exige cita, prohíbe comercializar y prohíbe copiar a soportes electrónicos de acceso multiusuario sin consentimiento escrito. El marco peruano y andino (Decisión 351 art. 28; D.Leg. 822 art. 78) protege una base de datos solo por la originalidad de su selección o disposición; no hay derecho sui generis. El usuario decidió el 2026-10-16 no solicitar consentimiento por ahora.

Las políticas de preservación detectaron además que un NAS institucional es un soporte multiusuario (incompatible con ENDES) y que Zenodo limita cada registro a 100 archivos y 50 GB.

## Alternativas

- **Espejo público de ENDES amparado en la Ley 27806:** descartado; la ley regula acceso a información pública, no otorga licencia de redistribución (informe 05).
- **Puntaje ponderado único para decidir nivel:** descartado por opaco; se eligen reglas ordenadas y auditables.
- **CC-BY-4.0 sobre toda copia y derivado:** descartado; incompatible con ODC-By (§4.2 y §4.4 exigen mantener la licencia) y con las fuentes que prohíben redistribuir.

## Decisión

1. **Cuatro niveles de congelamiento**, como en el manifiesto y el esquema del registry: `public-mirror-doi` (1), `restricted-mirror-doi` (2), `recipe-and-hash` (3), `cite-only` (4).
2. **Reglas de asignación, en orden:** R1 términos que prohíben redistribuir o sin licencia verificada → 3 o 4. R2 licencia abierta y riesgo de pérdida alto → 1 con partición o recorte a Perú aunque sea grande. R3 datos personales o de paciente → 4. R4 licencia abierta y riesgo bajo → 1 si el recorte pesa < 10 GB, si no 3. R5 el nivel 2 solo con autorización escrita de la fuente.
3. **Asignación vigente** (22 fuentes, detalle en el anexo 06): nivel 1 = RENIPRESS-SUSALUD y SIS (ODC-By), ERA5 recortado a Perú (CC-BY), CHIRPS (dominio público), GDELT (cita y enlace); nivel 2 = ninguna; nivel 3 = ENDES, ENAHO, censos INEI, MEF, RENAES/MINSA-IPRESS, HIS-MINSA, INFORHUS, SINADEF, CDC-MINSA, EsSalud, SENAMHI, NASA POWER, Defensoría, Google Mobility, espaciales locales; nivel 4 = INCOR (datos de paciente) y ACLED (EULA sin redistribución).
4. **ENDES queda en nivel 3** (decisión del usuario, 2026-10-16): el registry publica receta, sha256, términos y fecha; los bytes viven solo en el remote DVC privado (R2) y en una copia fría de un solo usuario; nunca en Zenodo ni en un NAS multiusuario. Sube a nivel 2 únicamente con consentimiento escrito del INEI, que puede solicitarse más adelante sin cambiar nada más.
5. **Qué se publica de una fuente de nivel 3:** solo **salidas transformadas** con cita: agregados, estimaciones, diccionarios estructurados, código y marts agregados. **Nunca marts a nivel de fila** derivados de ENDES u otra fuente de nivel 3; un mart fila-nivel de nivel 3 se queda en R2 con el mismo tratamiento que `raw/`. Esto resuelve la tensión entre el contrato aguas abajo (informe 19) y el nivel 3.
6. **Licencia de derivados:** CC-BY-4.0 solo para código, texto, diccionarios y derivados propios cuya fuente lo permita. Una base de datos derivada de una fuente ODC-By se publica bajo **ODC-By** (no se relicencia); CHIRPS (dominio público) y ERA5 (CC-BY) sí admiten CC-BY-4.0 con atribución. `LICENSE-DATA.md` se reescribe en la Fase 3 con esta tabla.
7. **Lo que declara todo espejo y todo manifiesto:** origen y URL, fecha de captura, sha256, URL y copia de los términos vigentes (`terms_snapshot_sha256`), licencia efectiva, aviso de no afiliación, atribución exigida, nivel y estado (`provisional`/`confirmed`), contacto de retiro.
8. **Preservación por nivel** (política `docs/preservation/plan-3-2-1.md`): R2 guarda los bytes de niveles 1–3; Zenodo solo 1 y 2; la tercera copia es disco frío (personal para nivel 3); nivel 4 no se copia. Los conjuntos con más de 100 archivos (CHIRPS, GDELT) se empaquetan por año antes de subir a Zenodo.

## Consecuencias

- Los manifiestos y punteros de ENDES ya reflejan `recipe-and-hash` con estado `confirmed` y la URL de la política ANDA (commits del 2026-10-16 en plantilla y registry).
- La skill `decide-freeze-level` (Fase 3) implementa las reglas R1–R5 y exige un ADR corto por fuente nueva; `audit-license` comprueba antes de cada release que ningún artefacto público contiene filas de una fuente de nivel 3.
- `LICENSE-DATA.md`, `CITATION.cff` y la página "Cómo citar" se actualizan en la Fase 3.
- **Provisional / revisión legal humana antes de la primera release:** compatibilidad CC-BY-4.0 con ODC-By (lectura propia); si el acceso `restricted` de Zenodo satisface el consentimiento del INEI para un futuro nivel 2; términos no localizados de MEF, SENAMHI, Defensoría, HIS-MINSA, NASA POWER y Google; tamaños estimados de ENDES, ENAHO, censos, MEF y ERA5-Perú.
