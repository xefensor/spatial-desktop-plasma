#!/usr/bin/env bash
set -euo pipefail
spatial_plasma_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node "$spatial_plasma_root/tests/test-actions.cjs"
python3 "$spatial_plasma_root/tests/test_panel.py"
cmake -S "$spatial_plasma_root/tests" -B "$spatial_plasma_root/build" -G Ninja
cmake --build "$spatial_plasma_root/build" -j 2
ctest --test-dir "$spatial_plasma_root/build" --output-on-failure
python3 "$spatial_plasma_root/scripts/package.py"
