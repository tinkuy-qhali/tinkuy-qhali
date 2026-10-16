# Anexo 08 — Esquema `procedencia` (propuesta)

```yaml
variable_id: ENDES_ANEMIA_NINO
procedencia:
  derivado_de:                 # prov:wasDerivedFrom / DataCite IsDerivedFrom
    - study_id: endes-2024-1629
      variable: HW56
      ref: https://doi.org/...     # DOI o URL
  regla:                       # prov:Activity + prov:used
    codigo: R/derive_anemia.R
    sha256: "..."
  version_regla: "1.0.0"       # DataCite IsVersionOf
  generado_por: https://orcid.org/...   # prov:wasAttributedTo
  fecha: 2026-10-16            # prov:generatedAtTime
  comparabilidad: "Ajuste por altitud desde 2019."
  lock: dvc.lock               # evidencia de ejecucion
```
