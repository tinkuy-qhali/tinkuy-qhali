"""Write the fixtures used by tests/test_check_research.sh into the directory given as argv[1]."""
import sys
from pathlib import Path

out = Path(sys.argv[1])

VALID = """---
item: 7
titulo: Espejos
modelo: sonnet
esfuerzo: medium
fecha: 2026-10-16
estado: borrador
---
# 07 — Espejos

## Pregunta
Qué espejar.

## Hallazgos
- Zenodo acepta 50 GB por registro (https://help.zenodo.org/docs/, 2026-10-16).
- Sin fuente aún **[provisional]**.

## Decisión propuesta
- Decisión: Zenodo | Alternativa descartada: OSF | Confianza: media

## Riesgos y provisional
- Cuotas pueden cambiar.

## Fuentes nuevas
- https://dataverse.org — alojamiento institucional.
- https://www.softwareheritage.org — código.
"""

BROKEN = """---
item: 8
titulo: Roto
modelo: sonnet
esfuerzo: medium
fecha: 16/10/2026
estado: borrador
---
# 08 — Roto

## Pregunta
{words}

## Hallazgos
- Afirmación sin fuente ni fecha.

## Decisión propuesta
- Decisión: x

## Fuentes nuevas
- https://solo-una.org — una.
""".format(words=" ".join(["palabra"] * 420))


def consolidated(n_rows: int) -> str:
    rows = "\n".join(f"| {i} | tema {i} | decisión {i} | alta |" for i in range(1, n_rows + 1))
    return f"""# 00 — Informe de investigación

## Tabla de decisiones
| Ítem | Tema | Decisión | Confianza |
|---|---|---|---|
{rows}

## Cinco preguntas
**¿Un solo modelo de datos?** Sí, por capas.
**¿Monorepo o multirepo?** Híbrido.
**¿R o Python principal?** R.
**¿Cuándo se abre otro repo?** Licencia distinta.
**¿Qué es esto en términos conocidos?** Research compendium (https://ejemplo.org, 2026-10-16).
"""


(out / "07-espejos.md").write_text(VALID, encoding="utf-8", newline="\n")
(out / "08-roto.md").write_text(BROKEN, encoding="utf-8", newline="\r\n")
(out / "00-informe-investigacion.md").write_text(consolidated(26), encoding="utf-8", newline="\n")
(out / "00-corto.md").write_text(consolidated(12), encoding="utf-8", newline="\n")
