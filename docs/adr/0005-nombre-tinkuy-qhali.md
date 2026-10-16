# ADR 0005 — Nombre del ecosistema: `tinkuy-qhali`

- **Estado:** aceptado; justificación lingüística **provisional**
- **Fecha:** 2026-10-16

## Contexto

Se necesitaba un nombre legible, buscable, neutral y disponible en GitHub (organización) y Zenodo (comunidad). El usuario pidió una palabra quechua que aluda a encuentro/confluencia y otra a salud.

## Candidatos evaluados (disponibilidad verificada el 2026-10-15/16)

| Nombre | Significado propuesto | GitHub org/usuario | Zenodo community | Observación |
|---|---|---|---|---|
| `tinkuy-qhali` (elegido) | *tinkuy* = encuentro, confluencia (de ríos, de caminos); *qhali* = sano | libre / libre | libre | Sin colisiones de marca en búsqueda web |
| `qhali-kawsay` | salud y vida | libre | libre | Pierde la metáfora de confluencia |
| `tinkuy-kawsay` | encuentro de vida | libre | libre | Alude a vida más que a salud |
| `tinkuy-salud` | híbrido quechua-español | libre | libre | Usuario prefirió quechua puro |
| `allin kawsay` | buen vivir | — | — | Descartado: nombre de una app del MINSA |
| `pe-health-data-commons`, `datos-salud-peru` | descriptivos | libre | libre | Descartados por preferencia de identidad |

## Decisión

- Ecosistema y organización GitHub: **`tinkuy-qhali`**.
- Repos: `tinkuy-qhali` (plantilla), `tinkuy-qhali-cdm`, `tinkuy-qhali-registry`, `tinkuy-qhali-endes` (Ronda 2). Prefijo interno de código: `tq_`.
- Grafía: *qhali* (variante Cusco-Collao); se documentan las variantes *qali*/*qhalli* en el manifiesto.

## Evidencia y lo que falta

Las fuentes en línea consultadas sobre el significado son de baja calidad (páginas de preguntas frecuentes). Una fuente sólida para verificar el uso de *qhali* en contexto de salud andina es Mujica Bermúdez, L. (2019), *Ukunchik: la naturaleza del cuerpo y la salud en el mundo andino*, INTE-PUCP. **Acción pendiente (Fase 5, identidad):** cotejar con el diccionario de la Academia Mayor de la Lengua Quechua o con hablantes antes de fijar la identidad visual; si el significado no se confirma, este ADR se supersede.

## Consecuencias

- Semver de datos y DOI usarán el prefijo `tinkuy-qhali`; cambiar el nombre tras la primera release rompería citas, por eso es irreversible.
- La identidad visual (Fase 5) parte de la metáfora de confluencia de ríos.
