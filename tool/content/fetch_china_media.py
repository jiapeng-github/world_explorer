#!/usr/bin/env python3
"""Check the China photo package, or restore missing licensed source thumbnails.

No API key or third-party package is required. All download URLs, rights notices,
dimensions and content hashes are pinned in editorial/china_assets.json.
Run without arguments for a completely offline integrity check.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import ssl
import struct
import time
from urllib.request import HTTPSHandler, ProxyHandler, Request, build_opener


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "tool/content/editorial/china_assets.json"


def image_size(data: bytes) -> tuple[int, int]:
    """Read PNG/JPEG dimensions without a platform-specific image dependency."""
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        return struct.unpack(">II", data[16:24])
    if data[:2] != b"\xff\xd8":
        raise ValueError("Downloaded file is not a JPEG or PNG")
    position = 2
    while position < len(data):
        if data[position] != 0xFF:
            raise ValueError("Invalid JPEG marker")
        while data[position] == 0xFF:
            position += 1
        marker = data[position]
        position += 1
        if marker in (0x01, 0xD8, 0xD9) or 0xD0 <= marker <= 0xD7:
            continue
        length = struct.unpack(">H", data[position:position + 2])[0]
        if marker in (0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7,
                      0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF):
            height, width = struct.unpack(">HH", data[position + 3:position + 7])
            return width, height
        position += length
    raise ValueError("JPEG has no size marker")


def verify(row: dict, data: bytes) -> None:
    if hashlib.sha256(data).hexdigest() != row["sha256"]:
        raise ValueError("SHA-256 differs from the reviewed asset")
    if image_size(data) != (row["width"], row["height"]):
        raise ValueError("Pixel dimensions differ from the hotspot reference")
    for key in ("caption", "credit", "sourceUrl", "license", "licenseUrl"):
        if not row.get(key):
            raise ValueError(f"Missing attribution field: {key}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fetch", action="store_true",
                        help="download missing new assets; existing files are never overwritten")
    parser.add_argument("--proxy", help="optional HTTP(S) proxy; otherwise use system proxy settings")
    parser.add_argument("--ca-file", help="optional trusted CA certificate bundle")
    args = parser.parse_args()
    document = json.loads(MANIFEST.read_text())
    ca_file = args.ca_file
    if ca_file is None and Path("/etc/ssl/cert.pem").exists():
        ca_file = "/etc/ssl/cert.pem"
    proxy = (ProxyHandler({"http": args.proxy, "https": args.proxy})
             if args.proxy else ProxyHandler())
    opener = build_opener(proxy, HTTPSHandler(context=ssl.create_default_context(cafile=ca_file)))
    failures = []
    total_bytes = 0
    for row in document["media"]:
        path = (ROOT / row["asset"]).resolve()
        if not path.is_relative_to(ROOT / "assets"):
            failures.append(f"{row['id']}: invalid asset path")
            continue
        try:
            if not path.exists() and args.fetch:
                if not row.get("downloadUrl"):
                    raise ValueError("Legacy hero image: restore assets/photos/china-wall.jpg from the project backup")
                request = Request(row["downloadUrl"], headers={
                    "User-Agent": "WorldExplorer/0.4 (educational offline photo package)"
                })
                for attempt in range(4):
                    try:
                        with opener.open(request, timeout=45) as response:
                            payload = response.read()
                        verify(row, payload)
                        path.parent.mkdir(parents=True, exist_ok=True)
                        path.write_bytes(payload)
                        break
                    except OSError:
                        if attempt == 3:
                            raise
                        time.sleep(8 * (attempt + 1))
                time.sleep(1)
            payload = path.read_bytes()
            verify(row, payload)
            total_bytes += len(payload)
        except (OSError, ValueError, KeyError, struct.error, IndexError) as error:
            failures.append(f"{row['id']}: {error}")
    if failures:
        print("\n".join(failures))
        return 1
    photos = sum(row.get("kind") == "realPhoto" for row in document["media"])
    print(f"Verified {len(document['media'])} assets: {photos} real photos, "
          f"{len(document['media']) - photos} artwork; {total_bytes:,} bytes.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
