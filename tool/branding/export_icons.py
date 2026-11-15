#!/usr/bin/env python3
"""Export the approved artwork to existing platform icon slots (macOS sips)."""

import json
from pathlib import Path
import struct
import subprocess

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/branding/world-atlas-icon-master.png"


def png_size(path):
    with path.open("rb") as stream:
        header = stream.read(26)
    if header[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"Not a PNG: {path}")
    return struct.unpack(">II", header[16:24])


def main():
    exports = {}
    for density, size in {"mdpi": 48, "hdpi": 72, "xhdpi": 96,
                          "xxhdpi": 144, "xxxhdpi": 192}.items():
        exports[ROOT / f"android/app/src/main/res/mipmap-{density}/ic_launcher.png"] = size
    for platform in ("ios", "macos"):
        directory = ROOT / platform / "Runner/Assets.xcassets/AppIcon.appiconset"
        for item in json.loads((directory / "Contents.json").read_text())["images"]:
            size = round(float(item["size"].split("x")[0]) * float(item["scale"].rstrip("x")))
            exports[directory / item["filename"]] = size
    exports[ROOT / "web/favicon.png"] = 32
    for size in (192, 512):
        exports[ROOT / f"web/icons/Icon-{size}.png"] = size
        exports[ROOT / f"web/icons/Icon-maskable-{size}.png"] = size
    exports[ROOT / "assets/branding/world-atlas-icon-1024.png"] = 1024

    if png_size(SOURCE)[0] != png_size(SOURCE)[1]:
        raise ValueError("Approved source must be square")
    for target, size in exports.items():
        target.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(["sips", "--resampleHeightWidth", str(size), str(size),
                        str(SOURCE), "--out", str(target)], check=True, capture_output=True)
        if png_size(target) != (size, size):
            raise ValueError(f"Incorrect exported size: {target}")
    print(f"Exported and verified {len(exports)} PNG icons from {SOURCE.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
