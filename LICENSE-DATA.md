# Licencia de los derivados de datos

Los derivados producidos por este ecosistema (diccionarios estructurados, `variable_registry`, marts, agregados) se publican bajo **Creative Commons Attribution 4.0 International (CC-BY-4.0)**, texto completo en https://creativecommons.org/licenses/by/4.0/legalcode.es, **condicionada** a los términos de la fuente original de cada dato (ADR 0004):

- Un derivado se publica bajo CC-BY-4.0 únicamente si el nivel de congelamiento de su fuente (ADR 0000, matriz de la Fase 1) permite redistribución.
- Si la fuente no lo permite, el repositorio publica la receta de descarga y los hashes, no los bytes.
- Cada `manifest.json` declara la licencia efectiva, la fuente, la URL de los términos y la fecha en que estaban vigentes.
- Los datos crudos (`raw/`) conservan la licencia de su productor (INEI, MEF, SUSALUD, SENAMHI, etc.) y nunca se relicencian.

Atribución sugerida: ver `CITATION.cff` y la página "Cómo citar" del sitio.
