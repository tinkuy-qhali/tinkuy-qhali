---
item: 16
titulo: Mermaid con estándar ISO 5807
modelo: haiku
esfuerzo: low
fecha: 2026-10-16
estado: borrador
---
# 16 — Mermaid con estándar ISO 5807

## Pregunta
¿Qué símbolos de ISO 5807 tienen forma exacta en Mermaid flowchart, desde qué versión, y qué alternativa usar cuando no la hay? El mapeo completo está en `docs/research/_16-anexo-mapeo.md`.

## Hallazgos
- ISO 5807:1985 define los símbolos de flujograma (proceso, decisión, documento, entrada/salida, almacenamiento, terminal, proceso predefinido, preparación, entrada manual, conector, línea de flujo); revisada en 2019. Fuente secundaria **[no oficial]** (https://en.wikipedia.org/wiki/Flowchart, 2026-10-16); la página de ISO devolvió HTTP 403, así que la lista oficial queda **[provisional]** (https://www.iso.org/standard/11955.html, 2026-10-16).
- Mermaid flowchart admite `@{ shape: ... }` desde v11.3.0 y unas 30 formas nuevas, entre ellas `rect`, `diam`, `doc`, `lean-r`, `cyl`, `lin-cyl`, `stadium`, `subproc`, `hex`, `sl-rect` (https://mermaid.js.org/syntax/flowchart.html, 2026-10-16).
- Las formas clásicas (`[]`, `{}`, `([])`, `[[]]`, `[()]`, `(())`, `[/ /]`) son conocidas, pero la sintaxis exacta de cada corchete queda **[provisional]**: la página consultada nombra las formas sin mostrar esa sintaxis (https://mermaid.js.org/syntax/flowchart.html, 2026-10-16).
- Diez de los once símbolos ISO tienen forma exacta con `@{ shape }`; el conector en página tiene aproximación (`circle`); el conector fuera de página no tiene forma equivalente (https://mermaid.js.org/syntax/flowchart.html, 2026-10-16).
- Mermaid se renderiza de forma nativa en la salida HTML de Quarto (https://quarto.org/docs/authoring/diagrams.html, 2026-10-16). La versión de Mermaid incluida en Quarto 1.10 no se pudo confirmar **[provisional]**.
- GitHub renderiza bloques de código `mermaid` en Markdown (https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-diagrams, 2026-10-16); la versión exacta que usa GitHub queda **[provisional]**.

## Decisión propuesta
- Decisión: usar Mermaid con `@{ shape }` (requiere Mermaid >= 11.3.0) y `classDef` para colores ISO; el conector fuera de página se dibuja como `circle` con etiqueta y `classDef` propio | Alternativa descartada: PlantUML o Graphviz (dependencia externa y sin render nativo en GitHub) | Confianza: media.
- Decisión: fijar la versión mínima en `docs/style/mermaid-iso5807.md` y comprobar Quarto y GitHub antes de adoptar | Alternativa descartada: asumir versión | Confianza: alta.

## Riesgos y provisional
- Versión de Mermaid de Quarto 1.10 y de GitHub: sin confirmar; se verifica en la Fase 2 con un diagrama de prueba renderizado.
- Lista oficial ISO no leída (403): confirmar con la norma. Sintaxis de corchetes clásica no verificada.
- Conector fuera de página: sin shape equivalente; usar `notch-pent` **[provisional]**.

## Fuentes nuevas
- https://www.iso.org/standard/11955.html — ficha oficial de ISO 5807 para confirmar la lista de símbolos.
- https://github.com/mermaid-js/mermaid/releases — notas de versión de Mermaid para confirmar cuándo entró `@{ shape }` y la versión que usan Quarto y GitHub.
