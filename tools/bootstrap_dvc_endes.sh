#!/usr/bin/env bash
# bootstrap_dvc_endes.sh — Phase 0.6 "raw data in the cloud today": DVC init + R2 remote (no credentials here),
# first small ENDES download (one module, one edition), manifest + sha256 + registry pointer, dvc add.
# Runs INSIDE the container:  docker compose run --rm -T pipeline bash tools/bootstrap_dvc_endes.sh
# Credentials live only in .dvc/config.local (gitignored), written by the user; `dvc push` is a separate step.
set -euo pipefail
cd /workspace

ACCOUNT_ID="${TQ_R2_ACCOUNT_ID:-5cd9171e5332beff49a1752f57985f6a}"   # not a secret (ADR 0007)
BUCKET="${TQ_R2_BUCKET:-tinkuy-qhali-raw}"
SOURCE=inei-endes; EDITION=2024; MODULE=1629; SURVEY_CODE=968
FILE="${SURVEY_CODE}-Modulo${MODULE}.zip"
DIR="raw/${SOURCE}/${EDITION}/${MODULE}"
ORIGIN="https://proyectos.inei.gob.pe/iinei/srienaho/descarga/SPSS/${FILE}"
REGISTRY_DIR="${TQ_REGISTRY_DIR:-/tmp/registry}"

echo "== dvc init + remote"
# --no-scm: DVC's embedded libgit2 cannot rename objects on Windows bind mounts; git is driven by the CLI instead
# (ADR 0007 addendum). .dvc files and .gitignore entries are committed explicitly.
[ -f .dvc/config ] || dvc init -q --no-scm
dvc cache dir /dvc-cache            # named volume (fast, outside NTFS); container path, same for every user of the image
dvc config cache.type "reflink,hardlink,copy"
dvc remote add -d -f r2 "s3://${BUCKET}"
dvc remote modify r2 region auto
dvc remote modify r2 endpointurl "https://${ACCOUNT_ID}.r2.cloudflarestorage.com"
cat .dvc/config

echo "== download ${ORIGIN}"
mkdir -p "$DIR"
if [ ! -s "$DIR/$FILE" ]; then
  curl -fSL --retry 3 -A "Mozilla/5.0 (tinkuy-qhali bootstrap)" -o "$DIR/$FILE" "$ORIGIN"
fi
ls -l "$DIR/$FILE"
unzip -l "$DIR/$FILE" | tail -n 8

echo "== dvc add"
dvc add -q "$DIR/$FILE"
cat "$DIR/$FILE.dvc"

echo "== manifest + pointer"
mkdir -p "$REGISTRY_DIR"
python tools/make_manifest.py --source "$SOURCE" --edition "$EDITION" --module "$MODULE" \
  --file "$DIR/$FILE" --origin-url "$ORIGIN" --terms-url "https://proyectos.inei.gob.pe/microdatos/" \
  --freeze-level recipe-and-hash --freeze-status provisional \
  --license-note "INEI publica los microdatos de ENDES en su portal sin un texto de licencia explicito en la pagina de descarga; aplican la Ley 27806 (transparencia) y el DS 016-2017-PCM (datos abiertos). Nivel provisional recipe-and-hash hasta el informe de la Fase 1, item 5." \
  --dvc-file "$DIR/$FILE.dvc" --registry-dir "$REGISTRY_DIR"
( cd "$DIR" && sha256sum -c manifest.sha256 )
echo "=====POINTER====="
cat "$REGISTRY_DIR/pointers/${SOURCE}-${EDITION}-${MODULE}.json"
