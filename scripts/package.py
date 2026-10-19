#!/usr/bin/env python3
"""Produce an installable widget archive without build output or test data."""
from pathlib import Path
import zipfile

root = Path(__file__).resolve().parents[1]
output = root / "out/spatial-apps.plasmoid"
output.parent.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED) as archive:
    for file in sorted((root / "apps").rglob("*")):
        if file.is_file():
            archive.write(file, file.relative_to(root / "apps"))
print(output)
