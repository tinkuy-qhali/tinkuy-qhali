@echo off
REM start.bat — one command to work inside the tinkuy-qhali container (Windows).
REM Host needs only Docker Desktop, Git, gh and Claude Code. Everything else lives in the image.
setlocal
cd /d "%~dp0"

where docker >nul 2>nul
if errorlevel 1 (
  echo Docker no esta instalado. Sigue docs\manual\install-manual.md o pega el prompt de install-agentic.md en Claude Code.
  exit /b 1
)
docker info >nul 2>nul
if errorlevel 1 (
  echo Docker Desktop no esta en ejecucion. Abrelo y vuelve a ejecutar start.bat.
  exit /b 1
)

REM Resource limits from the Docker VM (sized by %%UserProfile%%\.wslconfig from machine-profile.json): all CPUs, RAM - 1 GiB.
for /f %%i in ('docker info --format "{{.NCPU}}"') do set NCPU=%%i
for /f %%i in ('docker info --format "{{.MemTotal}}"') do set MEMB=%%i
REM cmd arithmetic is 32-bit, so drop the last 6 digits (bytes -> MB) before dividing to GiB (1074 MB ~ 1 GiB).
set MEMMB=%MEMB:~0,-6%
set /a MEMGIB=%MEMMB%/1074-1
if %MEMGIB% LSS 2 set MEMGIB=2
if "%TQ_WITH_JULIA%"=="" set TQ_WITH_JULIA=1
(
  echo TQ_CPUS=%NCPU%
  echo TQ_MEM=%MEMGIB%g
  echo TQ_WITH_JULIA=%TQ_WITH_JULIA%
) > .env

docker image inspect tinkuy-qhali:local >nul 2>nul
if errorlevel 1 (
  echo Construyendo la imagen ^(primera vez: 20-60 min segun la maquina^)...
  docker compose build
  if errorlevel 1 exit /b 1
)

echo Entrando al contenedor ^(CPU=%NCPU%, RAM=%MEMGIB%g^). Primera vez: ejecuta "claude login" dentro.
if "%~1"=="" (
  docker compose run --rm --service-ports pipeline claude
) else (
  docker compose run --rm --service-ports pipeline %*
)
endlocal
