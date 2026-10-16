# Anexo 24 — Borrador de run.sh, run.bat y test en máquina limpia

Borrador; no está instalado en la raíz. Supone `_targets.R` con un target final `tar_quarto(informe, "reports/index.qmd")` configurado para dejar `reports/index.html` **[provisional]**.

## run.sh
```bash
#!/usr/bin/env bash
# run.sh — pipeline a un clic, sin agente. Códigos: 0 ok; 10 sin Docker; 11 Docker apagado; 12 imagen;
# 13 datos; 20 falló tar_make; 21 falta reports/index.html.
set -uo pipefail
cd "$(dirname "$0")"
command -v docker >/dev/null 2>&1 || { echo "Docker no está instalado." >&2; exit 10; }
docker info >/dev/null 2>&1       || { echo "Docker Desktop no está en ejecución." >&2; exit 11; }

NCPU="$(docker info --format '{{.NCPU}}')"
MEM_GIB=$(( $(docker info --format '{{.MemTotal}}') / 1073741824 - 1 )); [ "$MEM_GIB" -lt 2 ] && MEM_GIB=2
printf 'TQ_CPUS=%s\nTQ_MEM=%sg\nTQ_WITH_JULIA=%s\n' "$NCPU" "$MEM_GIB" "${TQ_WITH_JULIA:-1}" > .env

if ! docker image inspect tinkuy-qhali:local >/dev/null 2>&1; then
  if [ -n "${TQ_IMAGE_REMOTE:-}" ]; then
    docker pull "$TQ_IMAGE_REMOTE" && docker tag "$TQ_IMAGE_REMOTE" tinkuy-qhali:local || exit 12
  else
    docker compose build || exit 12
  fi
fi

run() { docker compose run --rm -T pipeline "$@"; }
if [ "${TQ_SYNTHETIC:-0}" != "1" ]; then
  run dvc status -q >/dev/null 2>&1 || run dvc pull || { echo "dvc pull falló (¿.dvc/config.local?)." >&2; exit 13; }
fi

mkdir -p reports
run Rscript -e 'targets::tar_make()' || { echo "tar_make falló." >&2; exit 20; }
# Red de seguridad por el código de salida no verificado: ningún target puede quedar en errored.
run Rscript -e 'p <- targets::tar_progress(); if (any(p$progress == "errored")) quit(status = 1)' || exit 20
[ -s reports/index.html ] || { echo "Falta reports/index.html" >&2; exit 21; }
echo "Listo: reports/index.html"
```

## run.bat (equivalente mínimo)
```bat
@echo off
setlocal
cd /d "%~dp0"
where docker >nul 2>nul || (echo Docker no esta instalado. & exit /b 10)
docker info >nul 2>nul || (echo Docker Desktop no esta en ejecucion. & exit /b 11)
REM .env: igual que start.bat (CPU y RAM leidos de docker info)
docker image inspect tinkuy-qhali:local >nul 2>nul || (docker compose build || exit /b 12)
if not "%TQ_SYNTHETIC%"=="1" (
  docker compose run --rm -T pipeline dvc status -q >nul 2>nul || docker compose run --rm -T pipeline dvc pull || exit /b 13
)
if not exist reports mkdir reports
docker compose run --rm -T pipeline Rscript -e "targets::tar_make()" || exit /b 20
docker compose run --rm -T pipeline Rscript -e "p <- targets::tar_progress(); if (any(p$progress == 'errored')) quit(status = 1)" || exit /b 20
if not exist reports\index.html exit /b 21
echo Listo: reports\index.html
endlocal
```

## Prueba local en máquina limpia (tests/test_run_clean.sh)
```bash
#!/usr/bin/env bash
# Clon limpio bajo .tq-tmp/ (Docker en Windows solo monta rutas del host), volúmenes propios, sin claude.
set -euo pipefail
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")/.."
mkdir -p .tq-tmp && clone=$(mktemp -d "$PWD/.tq-tmp/run.XXXXXX")
hostpath=$(command -v cygpath >/dev/null 2>&1 && cygpath -w "$clone" || echo "$clone")
git clone -q . "$hostpath"
# Sin agente: un shim que falla si alguien invoca claude durante la corrida.
mkdir -p "$clone/.shim" && printf '#!/bin/sh\necho CLAUDE INVOCADO >&2; exit 99\n' > "$clone/.shim/claude" && chmod +x "$clone/.shim/claude"
( cd "$clone" && COMPOSE_PROJECT_NAME="tqclean$$" TQ_SYNTHETIC=1 PATH="$clone/.shim:$PATH" bash run.sh )
test -s "$clone/reports/index.html"
docker compose -p "tqclean$$" down -v >/dev/null 2>&1 || true
find "$clone" -mindepth 1 -delete
echo "PASS run.sh en clon limpio"
```
Nota: el shim solo cubre el host; el nombre de proyecto distinto crea volúmenes nuevos, así que `_targets/` parte vacío. Verificación dentro del contenedor de que no se invocó `claude`: **[provisional]**.

## CI (job adicional en el workflow `image`)
```yaml
  e2e:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: docker compose build   # o pull de la imagen publicada por el job build
      - run: TQ_SYNTHETIC=1 bash run.sh
      - uses: actions/upload-artifact@v4
        with: { name: informe, path: reports/index.html }
      - run: "! command -v claude"   # sin agente: no está instalado en el runner
```
