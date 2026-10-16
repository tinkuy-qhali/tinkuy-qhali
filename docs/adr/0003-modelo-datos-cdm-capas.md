# ADR 0003 — Modelo de datos: CDM propio por capas con vocabularios en formato OHDSI

- **Estado:** aceptado (detalle de entidades y matriz capa × estándar se fijan en Fase 2 tras la investigación de Fase 1, ítems 3 y 4)
- **Fecha:** 2026-10-16

## Contexto

Las fuentes iniciales son microdatos de encuestas con diseño complejo (ENDES, ENAHO), censos, presupuesto e infraestructura; más adelante datos clínicos a nivel paciente, clima, conflictos y movilidad. OMOP CDM está pensado para registros clínicos: no modela pesos, estratos ni PSU, y sus vocabularios tienen licencias heterogéneas (SNOMED exige membresía nacional; Perú no es miembro de SNOMED International). Forzar OMOP completo obligaría a mapear cada variable de encuesta a un `concept_id` estándar antes de poder usarla.

## Alternativas

- **OMOP CDM completo:** herramientas maduras (Atlas/HADES) pero pérdida del diseño muestral y mapeo manual masivo con poco retorno en Ronda 1. Descartado como núcleo.
- **DDI-CDI como núcleo:** nativo para encuestas, pero tooling inmaduro y sin puente natural a datos clínicos. Descartado como núcleo; se usa como estándar de la capa de encuesta en la matriz capa × estándar.
- **CDM propio por capas + formato OHDSI para la semántica:** elegido.

## Decisión

1. Capas con nombres fijos: `raw/` → `standardized/` → `harmonized/` → `marts/` (definidas en la especificación, Fase 2).
2. `harmonized/` usa entidades mínimas `location`, `period`, `household`, `person`, `facility`, `budget_line`, `event`, `climate_cell` (más las que justifique la Fase 1) y una tabla larga `observation` con `concept_id`. **Pesos, estratos y PSU son columnas de primera clase**, nunca atributos opcionales.
3. La capa semántica (`tinkuy-qhali-cdm`) usa el **formato** de tablas OHDSI (`concept`, `concept_relationship`, `vocabulary`), con vocabularios locales en el rango ≥ 2.000.000.000 y vocabularios estándar únicamente donde la licencia permita redistribuirlos (p. ej. LOINC con atribución; SNOMED excluido salvo licencia).
4. Vocabularios no clínicos (ISCO, ISCED, UBIGEO con equivalencias por año, clasificadores MEF, SDOH) entran como vocabularios locales con procedencia.
5. Una fuente clínica futura entra como OMOP sin re-mapear: sus `concept_id` estándar son válidos directamente porque el formato es el mismo.

## Consecuencias

- Hay un único modelo de datos por capas que conserva el diseño muestral; respuesta explícita a la pregunta de la especificación.
- El costo de mapear a vocabularios estándar se paga variable por variable, cuando aporta valor, y queda registrado en `variable_registry` con procedencia.
- Esta decisión es irreversible en el sentido de que los contratos de `harmonized/` y del `cdm` se versionan desde la primera release; cambiarla después exigiría un *major* de datos.
