# Image Display Suite

**English** | [简体中文](README.zh-CN.md)

![Image fixtures in different aspect ratios, with detail patterns and transparency](docs/hero.png)

An extensible collection of image test fixtures and generation tools for validating rendering, scaling, cropping, transparency, and decoding across applications and platforms.

Use the ready-made images in a photo viewer, gallery, website, or image-loading component, or use the included tools to generate and verify the fixtures yourself.

## What you can test

- **Aspect ratios and cropping** — square, portrait, landscape, widescreen, and phone-shaped images.
- **Long images and panoramas** — numbered sections, endpoint visibility, and zoom behavior in both orientations.
- **Detail and resolution** — text, fine lines, checkerboards, and matching aspect ratios at different resolutions.
- **Boundary behavior** — odd dimensions and adjacent cases around selected edge-length and total-pixel thresholds.
- **Transparency and encoding** — transparent and translucent regions, plus a JPEG/PNG pair made from identical source pixels.

[Browse the images](images/) · [View the fixture overview](docs/preview.jpg) · [Fixture catalog (Chinese)](docs/CATALOG.md) · [Testing guide (Chinese)](docs/TESTING.md)

## Get started

1. Download fixtures from [`images/`](images/) and load them into the application you want to test.
2. Start with common image shapes, then try long images, panoramas, transparency, and boundary cases.
3. Check fit versus crop behavior, reach every edge, and zoom into the text and line patterns. For an encoding comparison, use **PT020** and **PT021**, which share the same pre-encoding pixels.

**PT** stands for **PhotoTest**. Each fixture has a stable ID, and its filename includes its purpose, dimensions, and reduced aspect ratio:

```text
PT001_reading_1080x24000_9x200.jpg
│     │       │          └─ width:height ratio, reduced
│     │       └─ width × height in pixels
│     └─ fixture purpose
└─ stable PhotoTest ID
```

The overview is an index, not a sharpness reference. Inspect original files at the appropriate zoom level. Fine lines may appear gray or show moiré when downscaled.

Run **PT014** separately as a stress case: its 2160 × 48000 dimensions contain roughly 104 million pixels. The selected 8192-pixel edge and 8-million-pixel boundary cases are test points, not universal platform limits.

## Verify, regenerate, and package

Run these commands from the repository root:

```sh
# Verify existing fixtures. Python 3.9+, standard library only.
python3 scripts/verify.py

# Regenerate fixtures. Requires macOS, Python 3.9+, and Swift command-line tools.
python3 scripts/build.py

# Verify and package existing test images. Does not require Swift.
python3 scripts/build.py --package-only
```

The package is written to `dist/image-display-suite.zip`. It contains only the test images listed in `cases.json`, placed at the ZIP root for easy import. Source code, fonts, documents, previews, and header artwork remain in the repository. The MIT license notice is preserved in the ZIP comment without adding a non-image file. Use `--package` to regenerate and package in one command.

Verification and packaging use only Python and can run on macOS, Linux, and Windows. Verification checks filenames, dimensions, ratios, encodings, sizes, SHA-256 hashes, PNG CRCs, the alpha control, the format-pair record, and the pinned font/license files. It does not replace visual testing or fully decode every image.

Fixture generation reads the bundled font offline and does not install system fonts. The tested generation environment is macOS 26.5.2, Swift 6.3.3, and Python 3.9.6. Rasterization and encoding may vary across macOS or SDK versions; hashes in `manifest.json` verify the supplied files and do not promise byte-for-byte reproduction across environments.

## Repository layout

```text
images/                   Ready-to-use test fixtures
docs/                     Catalog, testing guide, overview, and introduction artwork
fonts/                    Pinned font, upstream sources, and license notices
scripts/                  Generation, verification, and packaging tools
cases.json                Fixture definitions: IDs, dimensions, and purpose
manifest.json             Image metadata, hashes, font details, and format-pair record
LICENSE                   Project MIT license
THIRD_PARTY_NOTICES.md     Third-party font notices
```

`.build/` and `dist/` are local output directories excluded from version control. See [CONTRIBUTING.md](CONTRIBUTING.md) for the contribution workflow (Chinese).

## License and provenance

The project's code, documentation, and image assets are provided under the [MIT License](LICENSE). Preserve the copyright and license notices when redistributing them.

The bundled **Noto Sans CJK SC Regular 2.004** font is separately licensed under **SIL Open Font License 1.1**. Its original font file, license, copyright notice, pinned source revision, and hashes are included in [`fonts/`](fonts/). The project MIT license does not replace the font's license; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

The header artwork was created with an image-generation model and is illustrative, not a measurement fixture. The fixtures and their overview are rendered by the included scripts. See [artwork generation details](docs/hero-generation.md) for the prompt and provenance.

This is a synthetic fixture collection, not a compatibility certification. It does not cover every codec, EXIF orientation, HDR, ICC color profile, animation format, or real-device performance characteristic.
