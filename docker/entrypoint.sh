#!/usr/bin/env bash
# tq-entrypoint — runs as root only long enough to make named volumes writable by the 'ubuntu' user, then drops
# privileges with setpriv. Why: Docker creates named volumes root-owned when their mount point is inside a bind mount,
# which would make raw/, .dvc/cache and _targets unwritable for the non-root user.
set -euo pipefail

TQ_USER="${TQ_USER:-ubuntu}"
TQ_UID="$(id -u "$TQ_USER")"
TQ_GID="$(id -g "$TQ_USER")"

for d in /dvc-cache /workspace/raw /workspace/_targets \
         /home/ubuntu/.julia /home/ubuntu/.cache /home/ubuntu/.claude /home/ubuntu/.local; do
  if [ -d "$d" ] && [ "$(stat -c %u "$d")" != "$TQ_UID" ]; then
    chown "$TQ_UID:$TQ_GID" "$d" 2>/dev/null || chmod a+rwx "$d" 2>/dev/null || true
  fi
done

if [ "$(id -u)" = "0" ]; then
  exec setpriv --reuid="$TQ_UID" --regid="$TQ_GID" --init-groups env HOME=/home/ubuntu USER="$TQ_USER" "$@"
else
  exec "$@"
fi
