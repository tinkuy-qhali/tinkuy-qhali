# Anexo — esquema de manifiesto por corrida (propuesta, borrador)

Campos JSON: `run_id`, `started_at`, `duration_s`, `code_version` (git SHA), `cdm_version`, `container_image_digest`, `params` (objeto), `inputs[]` ({`path`, `layer`, `sha256`, `contract_version`}), `outputs[]` (igual), `targets[]` (subconjunto de `tar_meta()`: name, data, command, depend, seconds), `validation` ({`passed`, `checks[]`}). Inspirado en el manifiesto de `dismodlite` (https://github.com/horaciochacon/dismodlite, 2026-10-16). **[provisional]**
