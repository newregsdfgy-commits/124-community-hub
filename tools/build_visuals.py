#!/usr/bin/env python3
"""Deterministic 124 Visuals source bundler.

src/*.lua are ordered source fragments sharing Luau lexical scope, not ModuleScripts.
They must be concatenated byte-for-byte. No injected require/loadstring, HTTP, or
runtime change is introduced by this builder.
"""
from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE_NAMES = (
    "00_config.lua",
    "01_access_gate.lua",
    "02_state_and_services.lua",
    "03_esp_tracker.lua",
    "04_lighting_and_booster.lua",
    "05_weapons_and_recoil.lua",
    "05_player_visuals.lua",
    "06_gui_runtime.lua",
    "07_esp_overlays.lua",
    "08_ui_controls.lua",
    "09_misc_and_diagnostics.lua",
    "10_run_and_cleanup.lua",
)
OUTPUT_NAMES = ("Hub.lua", "Visuals.lua")
SOURCE_HEADERS = (
    b"-- 124 Visuals v1.4.5",
    b"-- \xd0\x91\xd0\xbb\xd0\xbe\xd0\xba\xd0\xb8\xd1\x80\xd0\xbe\xd0\xb2\xd0\xba\xd0\xb0 \xd0\xb7\xd0\xb0\xd0\xbf\xd1\x83\xd1\x81\xd0\xba\xd0\xb0:",
    b"local state = {",
    b"-- ESP: ",
    b"-- Shared Lighting ownership:",
    b"local recoil = (function()",
    b"-- PLAYER VISUAL FX:",
    b"-- Bootstrap registered BEFORE",
    b"-- \xd0\x9b\xd0\xb8\xd0\xbd\xd0\xb8\xd0\xb8 \xd1\x81\xd0\xb2\xd0\xb5\xd1\x80\xd1\x85\xd1\x83",
    b"-- \xd0\x95\xd0\xb4\xd0\xb8\xd0\xbd\xd0\xb0\xd1\x8f \xd1\x81\xd0\xb5\xd1\x82\xd0\xba\xd0\xb0",
    b'addSection(pages.MISC, "WEAPONS 2.0"',
    b"-- Camera FOV ",
)


def bundle() -> bytes:
    pieces: list[bytes] = []
    for name, header in zip(SOURCE_NAMES, SOURCE_HEADERS, strict=True):
        path = ROOT / "src" / name
        data = path.read_bytes()
        if not data.startswith(header):
            raise ValueError(f"{name}: wrong source boundary or order")
        if not data.endswith(b"\n"):
            raise ValueError(f"{name}: missing final newline")
        pieces.append(data)
    return b"".join(pieces)


def write_atomic(path: Path, content: bytes) -> None:
    fd, name = tempfile.mkstemp(prefix=path.name + ".", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(content)
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="Compare generated and committed bundles")
    parser.add_argument("--write", action="store_true", help="Regenerate both entrypoints")
    args = parser.parse_args()
    if args.check == args.write:
        parser.error("choose exactly one of --check or --write")

    expected = bundle()
    if args.check:
        bad = []
        for name in OUTPUT_NAMES:
            path = ROOT / name
            if not path.is_file() or path.read_bytes() != expected:
                bad.append(name)
        if bad:
            print("FAIL: bundle out of sync:", ", ".join(bad))
            print("Run: python3 tools/build_visuals.py --write")
            return 1
        print("PASS: both bundles match 12 ordered source modules")
    else:
        for name in OUTPUT_NAMES:
            write_atomic(ROOT / name, expected)
        print("PASS: regenerated Hub.lua and Visuals.lua atomically")
    print("sha256:", hashlib.sha256(expected).hexdigest())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
