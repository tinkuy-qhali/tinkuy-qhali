#!/usr/bin/env python3
"""make_manifest.py - Write raw/<source>/<edition>/<module>/manifest.json, manifest.sha256 and a registry pointer.

Why: raw bytes never enter git; what enters git is their identity (SHA-256) plus everything a mirror needs to know
(origin, terms, retrieval date, freeze level). This script is the only writer of those three files so the formats stay
consistent with tinkuy-qhali-registry/schema/pointer.schema.json. Stdlib only; runs inside the container.

Usage (inside the container):
  python tools/make_manifest.py --source inei-endes --edition 2024 --module RECH0 \
      --file raw/inei-endes/2024/RECH0/RECH0.zip --origin-url URL --terms-url URL \
      --freeze-level recipe-and-hash --license-note "..." --registry-dir ../tinkuy-qhali-registry
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path


def sha256_of(path: Path, chunk: int = 1 << 20) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(chunk), b""):
            h.update(block)
    return h.hexdigest()


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--source", required=True, help="producer-survey slug, e.g. inei-endes")
    ap.add_argument("--edition", required=True)
    ap.add_argument("--module", required=True)
    ap.add_argument("--file", required=True, type=Path, help="raw file already downloaded")
    ap.add_argument("--origin-url", required=True)
    ap.add_argument("--terms-url", required=True)
    ap.add_argument("--terms-snapshot", type=Path, help="local copy of the terms page/PDF to hash (optional)")
    ap.add_argument("--freeze-level", required=True,
                    choices=["public-mirror-doi", "restricted-mirror-doi", "recipe-and-hash", "cite-only"])
    ap.add_argument("--freeze-status", default="provisional", choices=["provisional", "confirmed"])
    ap.add_argument("--license-note", required=True)
    ap.add_argument("--dvc-remote", default="r2", help="DVC remote name recorded as a location")
    ap.add_argument("--registry-dir", type=Path, default=Path("../tinkuy-qhali-registry"))
    ap.add_argument("--dvc-file", help="path of the .dvc file in the source repo (recorded in the pointer)")
    a = ap.parse_args()

    if not a.file.is_file():
        print(f"error: {a.file} not found", file=sys.stderr)
        return 2
    now = datetime.now(timezone.utc).isoformat(timespec="seconds")
    digest = sha256_of(a.file)
    size = a.file.stat().st_size
    pointer_id = f"{a.source}-{a.edition}-{a.module}".lower()

    manifest = {
        "pointer_id": pointer_id,
        "source": a.source, "edition": a.edition, "module": a.module,
        "filename": a.file.name, "sha256": digest, "size_bytes": size,
        "retrieved_at": now, "origin_url": a.origin_url, "terms_url": a.terms_url,
        "freeze_level": a.freeze_level, "freeze_level_status": a.freeze_status,
        "license_note": a.license_note,
        "never_edit": "raw/ is a byte-for-byte mirror; derived layers live in standardized/ and beyond",
    }
    if a.terms_snapshot and a.terms_snapshot.is_file():
        manifest["terms_snapshot_sha256"] = sha256_of(a.terms_snapshot)

    out_dir = a.file.parent
    (out_dir / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")
    (out_dir / "manifest.sha256").write_text(f"{digest}  {a.file.name}\n", encoding="utf-8", newline="\n")

    pointer = {k: manifest[k] for k in ("pointer_id", "source", "edition", "module", "filename", "sha256", "size_bytes",
                                        "retrieved_at", "origin_url", "terms_url", "freeze_level",
                                        "freeze_level_status", "license_note")}
    if "terms_snapshot_sha256" in manifest:
        pointer["terms_snapshot_sha256"] = manifest["terms_snapshot_sha256"]
    pointer["locations"] = [
        {"kind": "origin", "uri": a.origin_url},
        {"kind": "dvc-remote", "uri": f"dvc://{a.dvc_remote}/{digest[:2]}/{digest[2:]}", "verified_at": now},
    ]
    if a.dvc_file:
        pointer["dvc_file"] = a.dvc_file
    pdir = a.registry_dir / "pointers"
    pdir.mkdir(parents=True, exist_ok=True)
    ppath = pdir / f"{pointer_id}.json"
    ppath.write_text(json.dumps(pointer, indent=2, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")

    print(f"sha256={digest}\nsize_bytes={size}\nmanifest={out_dir / 'manifest.json'}\npointer={ppath}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
