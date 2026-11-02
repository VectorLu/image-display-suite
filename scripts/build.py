#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Regenerate on macOS; verify and package published fixtures on any Python platform."""
import argparse
import hashlib
import json
from pathlib import Path
import platform
import shutil
import subprocess
import sys
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def validate():
    subprocess.run([sys.executable, str(ROOT / "scripts/verify.py")], check=True)


def regenerate():
    if platform.system() != "Darwin" or shutil.which("swift") is None:
        raise RuntimeError("Regeneration requires macOS and Swift command-line tools; validation and --package-only only require Python.")
    for folder in ["images", "docs", ".build"]:
        (ROOT / folder).mkdir(exist_ok=True)
    cases = read_json(ROOT / "cases.json")
    # Never depend on files adjacent to the repository or remove user files.
    extras = {p.name for p in (ROOT / "images").iterdir()} - {s["filename"] for s in cases}
    if extras:
        raise RuntimeError(f"Move unexpected files out of images/ before regenerating: {sorted(extras)}")
    sources = read_json(ROOT / "fonts/SOURCES.json")
    for source in sources["files"]:
        path = ROOT / "fonts" / source["filename"]
        if hashlib.sha256(path.read_bytes()).hexdigest() != source["sha256"]:
            raise RuntimeError(f"Upstream file changed: {path.name}")
    with tempfile.TemporaryDirectory(prefix="image-display-suite-swift-") as cache:
        for renderer in ["generate-long.swift", "generate-patterns.swift"]:
            subprocess.run(["swift", "-module-cache-path", cache, str(ROOT / "scripts" / renderer), str(ROOT)], check=True)
    records = []
    for case in cases:
        path = ROOT / "images" / case["filename"]
        records.append(dict(case, bytes=path.stat().st_size, sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
    font = read_json(ROOT / ".build/font-info.json")
    pair = read_json(ROOT / ".build/format-pair-source-sha256.json")
    write_json(ROOT / "manifest.json", {
        "schema_version": 1, "license": "MIT", "font": font, "images": records,
        "verification": {"format_pair": {"ids": [20, 21], "source_sha256": pair}},
    })
    lines = ["# 图片清单", "", "尺寸按宽 × 高记录，比例为最简宽高比。PT 表示 PhotoTest，后接稳定的测试编号。", "",
             "| 文件名 | 分组 | 测试目的 |", "| --- | --- | --- |"]
    lines += [f"| [{s['filename']}](../images/{s['filename']}) | {s['group']} | {s['purpose']} |" for s in cases]
    (ROOT / "docs/CATALOG.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    validate()


def package():
    validate()
    # Only fixture images are archive members. Keep the MIT notice in the ZIP comment.
    names = [s["filename"] for s in read_json(ROOT / "cases.json")]
    destination = ROOT / "dist/image-display-suite.zip"
    destination.parent.mkdir(exist_ok=True)
    # Stable ordering and timestamps avoid irrelevant archive differences on one set of inputs.
    with zipfile.ZipFile(destination, "w", zipfile.ZIP_DEFLATED) as archive:
        archive.comment = (ROOT / "LICENSE").read_bytes()
        for name in sorted(names):
            path = ROOT / "images" / name
            if path.is_symlink():
                raise RuntimeError(f"Refusing to package symlink: {name}")
            entry = zipfile.ZipInfo(name, date_time=(2026, 1, 1, 0, 0, 0))
            entry.compress_type = zipfile.ZIP_DEFLATED
            entry.external_attr = 0o644 << 16
            archive.writestr(entry, path.read_bytes())
    with zipfile.ZipFile(destination) as archive:
        if sorted(archive.namelist()) != sorted(names) or archive.testzip() is not None:
            raise RuntimeError("Image-only archive content or integrity check failed")
        if archive.comment != (ROOT / "LICENSE").read_bytes():
            raise RuntimeError("Archive MIT notice is missing")
    print(f"Packaged {len(names)} test images: {destination}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    choice = parser.add_mutually_exclusive_group()
    choice.add_argument("--package", action="store_true", help="regenerate, verify, and create an image-only archive")
    choice.add_argument("--package-only", action="store_true", help="verify and package test images without rendering")
    args = parser.parse_args()
    if not args.package_only:
        regenerate()
    if args.package or args.package_only:
        package()


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, subprocess.CalledProcessError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        sys.exit(1)
