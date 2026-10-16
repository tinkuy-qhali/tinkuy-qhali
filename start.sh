#!/usr/bin/env bash
# start.sh — one command to work inside the tinkuy-qhali container (Linux/macOS/Git Bash).
# Host needs only Docker, Git, gh and Claude Code. Everything else lives in the image.
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker no está instalado. Sigue docs/manual/install-manual.md (o pega el prompt de install-agentic.md en Claude Code)." >&2
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  echo "Docker Desktop no está en ejecución. Ábrelo y vuelve a ejecutar start.sh." >&2
  exit 1
fi

# Resource limits from the Docker VM (already sized by .wslconfig from machine-profile.json): all CPUs, RAM minus 1 GiB.
NCPU="$(docker info --format '{{.NCPU}}')"
MEM_BYTES="$(docker info --format '{{.MemTotal}}')"
MEM_GIB=$(( MEM_BYTES / 1073741824 - 1 )); [ "$MEM_GIB" -lt 2 ] && MEM_GIB=2
printf 'TQ_CPUS=%s\nTQ_MEM=%sg\nTQ_WITH_JULIA=%s\n' "$NCPU" "$MEM_GIB" "${TQ_WITH_JULIA:-1}" > .env

if ! docker image inspect tinkuy-qhali:local >/dev/null 2>&1; then
  echo "Construyendo la imagen (primera vez: 20-60 min según la máquina)..."
  docker compose build
fi

echo "Entrando al contenedor (CPU=$NCPU, RAM=${MEM_GIB}g). Primera vez: ejecuta 'claude login' dentro."
exec docker compose run --rm --service-ports pipeline "${@:-claude}"
