#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Verify published fixtures using only the Python standard library."""
import binascii
import hashlib
import json
import math
from pathlib import Path
import struct
import sys
import zlib

ROOT = Path(__file__).resolve().parents[1]


def require(condition, message):
    if not condition:
        raise ValueError(message)


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def digest(path):
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def image_info(path):
    data = path.read_bytes()
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        pos, header, compressed, ended = 8, None, [], False
        while pos + 12 <= len(data):
            length = struct.unpack_from(">I", data, pos)[0]
            kind = data[pos + 4:pos + 8]
            end = pos + 8 + length
            require(end + 4 <= len(data), f"Truncated PNG: {path.name}")
            payload = data[pos + 8:end]
            crc = struct.unpack_from(">I", data, end)[0]
            require(binascii.crc32(kind + payload) & 0xffffffff == crc, f"PNG CRC mismatch: {path.name}")
            if kind == b"IHDR":
                require(pos == 8 and length == 13, "Invalid PNG header")
                header = struct.unpack(">IIBBBBB", payload)
            if kind == b"IDAT":
                compressed.append(payload)
            if kind == b"IEND":
                ended = True
                break
            pos = end + 4
        require(header is not None and ended and compressed, f"Incomplete PNG: {path.name}")
        return {"width": header[0], "height": header[1], "format": "png",
                "depth": header[2], "color_type": header[3], "interlace": header[6],
                "compressed": b"".join(compressed)}
    require(data.startswith(b"\xff\xd8") and data.endswith(b"\xff\xd9"), f"Invalid JPEG: {path.name}")
    pos = 2
    sof = {0xc0, 0xc1, 0xc2, 0xc3, 0xc5, 0xc6, 0xc7, 0xc9, 0xca, 0xcb, 0xcd, 0xce, 0xcf}
    while pos < len(data):
        require(data[pos] == 0xff, f"Invalid JPEG segment: {path.name}")
        while pos < len(data) and data[pos] == 0xff:
            pos += 1
        require(pos < len(data), "Truncated JPEG marker")
        marker = data[pos]
        pos += 1
        if marker in {0xd8, 0xd9, 0x01} or 0xd0 <= marker <= 0xd7:
            continue
        require(pos + 2 <= len(data), "Truncated JPEG segment")
        length = struct.unpack_from(">H", data, pos)[0]
        require(length >= 2 and pos + length <= len(data), "Invalid JPEG segment size")
        if marker in sof:
            require(length >= 8, "Invalid JPEG frame header")
            h, w = struct.unpack_from(">HH", data, pos + 3)
            return {"width": w, "height": h, "format": "jpg"}
        if marker == 0xda:
            break
        pos += length
    raise ValueError(f"Missing JPEG frame header: {path.name}")


def verify_alpha(info):
    """Reconstruct the alpha channel of the RGBA8 control, including PNG row filters."""
    require((info["depth"], info["color_type"], info["interlace"]) == (8, 6, 0), "Alpha control must be non-interlaced RGBA8")
    w, h = info["width"], info["height"]
    expected = (w * 4 + 1) * h
    decoder = zlib.decompressobj()
    raw = decoder.decompress(info["compressed"], expected + 1)
    require(len(raw) == expected and decoder.eof, "Invalid alpha-control pixel stream")
    previous, levels = [0] * w, set()
    for y in range(h):
        offset = y * (w * 4 + 1)
        filt = raw[offset]
        require(filt <= 4, "Invalid PNG filter")
        current = [0] * w
        for x in range(w):
            a, b, c = current[x - 1] if x else 0, previous[x], previous[x - 1] if x else 0
            prediction = 0
            if filt == 1:
                prediction = a
            elif filt == 2:
                prediction = b
            elif filt == 3:
                prediction = (a + b) // 2
            elif filt == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                prediction = a if pa <= pb and pa <= pc else b if pb <= pc else c
            current[x] = (raw[offset + 1 + x * 4 + 3] + prediction) & 255
        levels.update(current)
        previous = current
    require(0 in levels and 255 in levels and any(0 < v < 255 for v in levels), "Alpha control lacks transparent, translucent, or opaque pixels")


def verify(root=ROOT):
    cases = read_json(root / "cases.json")
    manifest = read_json(root / "manifest.json")
    require(manifest.get("schema_version") == 1, "Unsupported manifest schema")
    require(manifest.get("license") == "MIT", "Unexpected project license")
    require(cases and len({s["id"] for s in cases}) == len(cases), "Missing or duplicate case IDs")
    require(len({s["filename"] for s in cases}) == len(cases), "Duplicate filenames")
    indexed = {s["id"]: s for s in manifest["images"]}
    require(len(indexed) == len(cases) == len(manifest["images"]), "Case/manifest count mismatch")
    expected = {s["filename"] for s in cases}
    actual = {p.name for p in (root / "images").iterdir()}
    require(expected == actual, f"Image set mismatch: missing={expected-actual}, extra={actual-expected}")
    for case in cases:
        name = case["filename"]
        require(Path(name).name == name and "\\" not in name, "Unsafe filename")
        w, h = case["width"], case["height"]
        require(w > 0 and h > 0, "Non-positive dimensions")
        g = math.gcd(w, h)
        require(case["ratio"] == f"{w//g}x{h//g}", f"Incorrect aspect ratio: {name}")
        require(name.startswith(f"PT{case['id']:03}_") and name.endswith(f"_{w}x{h}_{case['ratio']}" + Path(name).suffix), f"Incorrect filename: {name}")
        record = indexed[case["id"]]
        require(all(record.get(k) == v for k, v in case.items()), f"Case/manifest metadata mismatch: {name}")
        path = root / "images" / name
        require(not path.is_symlink(), f"Symlinks are not fixtures: {name}")
        require(path.stat().st_size == record["bytes"] and digest(path) == record["sha256"], f"File hash/size mismatch: {name}")
        info = image_info(path)
        require((info["width"], info["height"]) == (w, h), f"Encoded dimensions mismatch: {name}")
        require(Path(name).suffix == "." + info["format"], f"Encoded format mismatch: {name}")
        if case["id"] == 19:
            verify_alpha(info)
    pair = manifest["verification"]["format_pair"]
    a, b = pair["ids"]
    require(pair["source_sha256"][str(a)] == pair["source_sha256"][str(b)], "Format-pair source pixels do not match")
    require((indexed[a]["width"], indexed[a]["height"]) == (indexed[b]["width"], indexed[b]["height"]), "Format-pair sizes differ")
    require({Path(indexed[a]["filename"]).suffix, Path(indexed[b]["filename"]).suffix} == {".jpg", ".png"}, "Format-pair encodings must differ")
    sources = read_json(root / "fonts" / "SOURCES.json")
    for source in sources["files"]:
        name = source["filename"]
        require(Path(name).name == name and "\\" not in name, "Unsafe font source filename")
        path = root / "fonts" / name
        require(not path.is_symlink() and path.stat().st_size == source["bytes"] and digest(path) == source["sha256"], f"Upstream font/license hash mismatch: {name}")
    for name in ["LICENSE", "THIRD_PARTY_NOTICES.md", "fonts/COPYRIGHT.txt", "fonts/OFL-1.1.txt"]:
        require((root / name).is_file(), f"Missing license material: {name}")
    copyright_notice = (root / "fonts/COPYRIGHT.txt").read_text(encoding="utf-8")
    require(manifest["font"]["copyright"] in copyright_notice, "Font copyright notice is missing")
    require("SIL Open Font License" in copyright_notice, "Font license notice is missing")
    return len(cases)


if __name__ == "__main__":
    try:
        print(f"PASS: {verify()} images; names, dimensions, ratios, formats, hashes, alpha control, format-pair record and upstream font/license hashes.")
    except (ValueError, KeyError, OSError, struct.error, zlib.error) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        sys.exit(1)
