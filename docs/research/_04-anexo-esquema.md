# Anexo — esquema mínimo por variable (borrador)

```yaml
id: endes2024.hv005            # estable, único
name: HV005
label: Peso de la vivienda      # etiqueta del .sav (primaria)
definition: ...                 # texto humano; PDF INEI solo contraste
domain: demografia
type: integer|number|string|categorical|date   # Table Schema
unit: ...
categories: [{value: 1, label: ...}]            # de variable_value_labels
missingValues: [{value: 9, label: No sabe}]     # de missing_ranges
constraints: {required: false, minimum: 0}
x_role: weight|stratum|psu|id|none              # diseño muestral
x_universe: ...
x_derivation: ...               # regla o null
sources: [{edition: ENDES 2024, file: ..., module: ...}]
concept_id: ...
provenance: {extracted_by: pyreadstat, sha256: ..., pdf_checked: true}
status: draft|reviewed|deprecated
version: 0.1.0
```
