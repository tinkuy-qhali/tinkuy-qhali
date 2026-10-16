---
titulo: Estilo de código R
estado: borrador
fecha: 2026-10-16
fase_aplicacion: F3
fuentes: [docs/research/22-codigo-r-y-pipelines-hibridos.md, docs/research/23-r-package-scout.md, docs/research/_23-anexo-skill.md, docs/research/26-lo-que-falta.md, docs/research/13-nomenclatura-bitacoras-metaaprendizaje.md, docs/research/04-diccionarios-para-agentes.md, benchmarks/results.md]
---
# Política: Estilo de código R

## Propósito
Fija cómo se escribe, se nombra, se prueba y se aprende código R en tinkuy-qhali para que sea legible, verificable y reproducible por humanos y agentes. R es el lenguaje principal; Python y Julia entran solo como procesos que intercambian Parquet. Las reglas se hacen cumplir con herramientas (pre-commit, `lintr`, `testthat`), no con recordatorios.

## Reglas
R1. Todo código R sigue la guía de estilo tidyverse, aplicada con `styler` (`style-files`) y revisada con `lintr`; ambos corren en pre-commit y en CI, y un commit que falle no se acepta. — **Por qué:** la guía se aplica con `styler` y `lintr`, y `precommit` trae los hooks listos (informe 22). — **Se verifica con:** hooks `style-files` y `lintr` de `lorenzwalthert/precommit`; `pre-commit run --all-files` en CI.
R2. Cada función pública lleva roxygen2 (`@param`, `@return`, `@examples` mínimos) y la documentación generada se mantiene sincronizada. — **Por qué:** el hook `roxygenize` evita que `man/` y el código diverjan (informe 22). — **Se verifica con:** hook `roxygenize`; `devtools::document()` sin diff en CI.
R3. Las funciones son cortas: una responsabilidad, idealmente ≤ 40 líneas y complejidad ciclomática ≤ 15 [propuesta]; lo que no cabe se parte en funciones con nombre propio. — **Por qué:** funciones pequeñas se prueban y se leen; los agentes editan mejor unidades acotadas. — **Se verifica con:** `cyclocomp_linter(15)` en `.lintr`; el límite de 40 líneas es manual.
R4. Objetos, argumentos y columnas en `snake_case` ASCII; las funciones se nombran con verbo (`leer_modulo()`, `ponderar_media()`, `validar_capa()`); nada de `T`/`F`. — **Por qué:** la guía tidyverse lo exige y la convención del repo es ASCII legible por máquina (informes 13 y 22). — **Se verifica con:** `object_name_linter("snake_case")`, `T_and_F_symbol_linter` (por defecto).
R5. Los archivos de script se nombran `NN-verbo-objeto.R` en `kebab-case` ASCII, sin espacios ni acentos; dentro del archivo rige R4. — **Por qué:** el informe 13 fija `kebab-case` para archivos y la guía tidyverse `snake_case` para objetos: son ámbitos distintos, no una contradicción. — **Se verifica con:** `tests/test_naming.sh` [propuesta].
R6. El NA nunca es implícito: cada `mean()`, `sum()` o conteo declara `na.rm = TRUE` o `FALSE` a propósito, y los códigos de no respuesta (8, 9, 98, 99...) se convierten a `NA` usando `missingValues` del diccionario, no valores escritos a mano. — **Por qué:** el benchmark excluye los NA del numerador y del denominador y decide el manejo una sola vez (`benchmarks/README.md`); el diccionario es la fuente única (informe 04). — **Se verifica con:** `testthat` con casos que contienen NA; revisión manual de llamadas sin `na.rm`.
R7. Las estimaciones de encuestas usan el diseño muestral (`survey`/`srvyr`: `as_survey_design()` con pesos, estratos y conglomerados); nunca `mean()` ni `table()` sin diseño sobre microdatos ENDES/ENAHO. — **Por qué:** `srvyr` da sintaxis dplyr sobre `survey` y ambos están en `env/r/packages.txt` (informe 22). — **Se verifica con:** `undesirable_function_linter` en `R/estimacion*.R` [propuesta]; revisión manual.
R8. Parquet es el formato de las cuatro capas del ADR 0003 (`raw/` conserva el original; `standardized/`, `harmonized/`, `marts/` en Parquet) y de todo intercambio entre lenguajes; los objetos de `targets` con data frames usan `format = "parquet"` y los archivos de otros lenguajes `format = "file"`. — **Por qué:** Parquet es el contrato entre lenguajes y `targets` lo soporta nativamente (informes 10 y 22). — **Se verifica con:** `targets::tar_manifest()` revisado por `tests/test_formats.R` [propuesta].
R9. Prohibido `setwd()`, rutas absolutas y rutas con separadores del sistema; las rutas se arman con `here::here()` o `fs::path()` relativas a la raíz del proyecto. — **Por qué:** el código debe correr igual en el contenedor, en CI y en otra máquina. — **Se verifica con:** `undesirable_function_linter(setwd)`, `absolute_path_linter`, `nonportable_path_linter`.
R10. Prohibido `library()`/`require()` dentro de funciones; se usa `paquete::funcion()` y las dependencias se declaran en `env/r/packages.txt` y `renv.lock`. — **Por qué:** `library()` oculta dependencias y contamina el espacio de nombres; la imagen solo trae lo curado. — **Se verifica con:** `library_call_linter` y `undesirable_function_linter` [propuesta]; `tools/check_renv_drift.py` en CI.
R11. Toda función con lógica nueva lleva test `testthat` (caso típico, borde y NA). Si una etapa se reescribe en otro lenguaje o motor, un test de equivalencia numérica compara contra la referencia R con tolerancia explícita. — **Por qué:** las 18 variantes del join coinciden con diferencia ≤ 4e-13 y la microsimulación se valida con z y χ² (`benchmarks/results.md`). — **Se verifica con:** `testthat::test_dir("tests/testthat")`; test de equivalencia por etapa [propuesta].
R12. En equivalencias, determinista = tolerancia relativa ≤ 1e-8 (agregaciones, joins); estocástico = comparación distribucional (|z| ≤ 4 contra la expectativa analítica y χ² con p > 1e-4), nunca bit a bit entre generadores distintos. — **Por qué:** el RNG difiere entre R, DuckDB, pyarrow y Julia, y 1e-3 no sirve como criterio con N = 1e6 (`benchmarks/results.md`). — **Se verifica con:** helper `expect_equivalente()` [propuesta] en `tests/testthat`.
R13. Un paquete que el agente no conoce no se usa hasta correr la skill `r-package-scout` y dejar `docs/packages/<pkg>.md`; la skill no instala nada, solo propone la línea para `env/r/packages.txt`, y la decisión es del usuario. — **Por qué:** evita código escrito de memoria sobre APIs que no se leyeron (informe 23). — **Se verifica con:** skill `r-package-scout`; comprobación en CI de que cada `pkg::` usado tenga ficha o esté en `packages.txt` [propuesta].

## Qué hace el agente y qué no
- Hace: formatea con `styler` antes de commitear; escribe roxygen2 y tests con cada función; declara `na.rm` y diseño muestral; lee el diccionario para los códigos de no respuesta; invoca `r-package-scout` ante un paquete nuevo.
- No hace: desactivar `lintr` o `styler` con `# nolint` sin comentario y ADR; usar `setwd()`, rutas absolutas o `library()` en funciones; promediar microdatos sin diseño; instalar paquetes en la imagen; declarar equivalente una reescritura sin test numérico ejecutado.

## Mecanismos que la hacen cumplir (Fase 3)
| Mecanismo | Tipo (hook/test/CI/skill/lintr) | Evento o disparador | Estado |
|---|---|---|---|
| `style-files` (`styler`) | hook | pre-commit | por implementar |
| `lintr` con `.lintr` del repo | lintr | pre-commit y CI | por implementar |
| `roxygenize` | hook | pre-commit | por implementar |
| `pre-commit run --all-files` | CI | `validate.yml`, cada PR | por implementar |
| `tests/testthat/` y helper `expect_equivalente()` | test | CI | por implementar |
| `tests/test_formats.R` (Parquet/file en `targets`) | test | CI | por implementar |
| `tests/test_naming.sh` | test | CI | por implementar |
| Skill `r-package-scout` (`.claude/skills/r-package-scout/SKILL.md`) | skill | paquete ausente de `packages.txt` | por implementar |
| Comprobación de fichas `docs/packages/<pkg>.md` | CI | PR que añade `pkg::` nuevo | por implementar |

## Configuración propuesta
`.lintr` [propuesta]. `cyclocomp_linter` requiere el paquete `cyclocomp`, hoy fuera de `env/r/packages.txt`.
```
linters: linters_with_defaults(
    line_length_linter(80L),
    object_name_linter(styles = "snake_case"),
    object_length_linter(30L),
    cyclocomp_linter(15L),
    absolute_path_linter(lax = TRUE),
    nonportable_path_linter(),
    library_call_linter(),
    undesirable_function_linter(c(
      setwd = "usar here::here() o fs::path()",
      require = "usar pkg::fun()",
      attach = "usar pkg::fun()"
    ))
  )
encoding: "UTF-8"
exclusions: list("renv", "benchmarks/.cache", ".tq-tmp")
```
`.pre-commit-config.yaml` mínimo [propuesta]; `rev` se fija a la última etiqueta al implementar. `roxygenize` exige un `DESCRIPTION` (compendio con `R/`); hoy no existe [provisional].
```
repos:
  - repo: https://github.com/lorenzwalthert/precommit
    rev: <etiqueta>
    hooks:
      - id: style-files
        args: [--style_pkg=styler, --style_fun=tidyverse_style]
      - id: lintr
      - id: roxygenize
  - repo: https://github.com/gitleaks/gitleaks
    rev: <etiqueta>
    hooks:
      - id: gitleaks
```

## Provisional
- Los hooks de `precommit` no se probaron en el contenedor (informe 22); se cierran en Fase 3.
- `.pre-commit-config.yaml` no existe aún; entra en la Ronda 1 con gitleaks (informe 26).
- Ayuda offline (`Rd2txt`, `vignette()`, `citation()`) y `pak::pkg_deps()` de la skill no se ejecutaron; la skill y su eval se prueban en el contenedor en Fase 2 (informe 23). `mcptools`/`btw` quedan opcionales y sin licencia confirmada.
- Umbrales de longitud (40 líneas) y complejidad (15) son [propuesta] sin fuente; se ajustan tras la Fase 3.

## Fuentes
- docs/research/22-codigo-r-y-pipelines-hibridos.md; docs/research/23-r-package-scout.md y _23-anexo-skill.md; docs/research/26-lo-que-falta.md; docs/research/13-nomenclatura-bitacoras-metaaprendizaje.md; docs/research/04-diccionarios-para-agentes.md; benchmarks/README.md y benchmarks/results.md.
- https://style.tidyverse.org/ (2026-10-16)
- https://lorenzwalthert.github.io/precommit/articles/available-hooks.html (2026-10-16)
- https://cran.r-project.org/web/packages/srvyr/vignettes/srvyr-vs-survey.html (2026-10-16)
- https://docs.ropensci.org/targets/reference/tar_target.html (2026-10-16)
- https://datapackage.org/standard/table-schema/ (2026-10-16)
- https://github.com/gitleaks/gitleaks (2026-10-16)
