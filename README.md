# ftl-multiverse-mac

Install native macOS `FTL: Multiverse` into the real Mac `FTL.app`.

This repo builds native macOS `Hyperspace`, downloads the validated `Multiverse` files, patches a duplicate `FTL.app`, and re-signs the result so it launches from Finder.

## Quick Start

1. Clone this repo
2. Make sure you have a Mac `FTL.app`
3. Make sure Xcode Command Line Tools are installed
4. Run:

```bash
./scripts/install_native_multiverse_macos.sh "/path/to/FTL.app"
```

Example:

```bash
./scripts/install_native_multiverse_macos.sh "/Users/yourname/Documents/FTL Advanced Edition.app"
```

By default this creates a sibling app named:

```bash
FTL Multiverse.app
```

Your original app is left untouched.

## What It Does

The installer script:

- clones the pinned upstream `FTL-Hyperspace` source if needed
- builds native macOS `Hyperspace` for `FTL 1.6.12` and `1.6.13`
- downloads the validated `Multiverse` release files
- duplicates your `FTL.app`
- patches the duplicate app's `ftl.dat`
- installs `Hyperspace.command` and the matching macOS `.dylib`
- updates `CFBundleExecutable`
- re-signs the final app with ad-hoc `codesign`

## Supported Inputs

Currently validated in this repo:

- macOS `FTL.app`
- `FTL 1.6.12`
- `FTL 1.6.13`
- Apple Silicon and Intel hosts

Validated content/tool versions:

- `FTL-Hyperspace` source ref: `55f0d96a4746e4ac6fc67110070a41264321437a`
- `Multiverse` assets: `v5.5`
- `Multiverse` data: `v5.5.1`
- `ftlman`: `v0.7.2`

## Requirements

- macOS
- a real `FTL.app` bundle
- internet access for first-run downloads
- Xcode Command Line Tools

## Scripts

- `scripts/install_native_multiverse_macos.sh`
  - one-shot installer for end users
- `scripts/build_upstream_native_macos.sh`
  - build/package native macOS `Hyperspace` only
- `scripts/run_upstream_native_macos_smoke_test.sh`
  - advanced validation against a real `FTL.app`

## More Info

See:

- `docs/native-macos-multiverse.md`

## Notes

- Large downloads and build artifacts live under `tmp/` and `upstream/`, which are ignored by Git.
- The installer refuses to overwrite an existing output app.
- If you want a fresh build cache, delete `tmp/` and `upstream/` and run the installer again.
- If macOS complains after moving the final app elsewhere, re-run:

```bash
codesign -f -s - --timestamp=none --all-architectures --deep "/path/to/FTL Multiverse.app"
```
