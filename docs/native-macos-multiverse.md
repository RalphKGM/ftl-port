# Native macOS Multiverse

This repo now contains a reproducible workflow for installing native macOS `FTL: Multiverse` on top of the Mac `FTL.app`.

## What this repo automates

It does two separate jobs:

1. Build native macOS `Hyperspace` from source
2. Patch official `Multiverse` data into a duplicate `FTL.app`

That split matters:

- `Hyperspace` is the native code injection/framework layer
- `Multiverse` is the content overhaul that depends on `Hyperspace`

## Versions validated in this repo

These are the exact known-good inputs currently wired into the automation:

- `FTL-Hyperspace` source ref:
  - `55f0d96a4746e4ac6fc67110070a41264321437a`
- `Multiverse` assets:
  - `v5.5`
- `Multiverse` data:
  - `v5.5.1`
- `ftlman`:
  - `v0.7.2`

The script intentionally pins these versions because they are the combination that was validated locally.

## One-shot install

From the repo root:

```bash
./scripts/install_native_multiverse_macos.sh "/path/to/FTL.app"
```

By default, that creates a sibling app named:

```bash
FTL Multiverse.app
```

You can also choose the output path explicitly:

```bash
./scripts/install_native_multiverse_macos.sh "/path/to/FTL.app" "/path/to/FTL Multiverse.app"
```

## What the installer does

The script will:

- clone the pinned `FTL-Hyperspace` upstream checkout if `upstream/FTL-Hyperspace` is missing
- build native macOS `Hyperspace` dylibs for `1.6.12` and `1.6.13`
- package the macOS `Hyperspace` release files
- download the validated `Multiverse` assets and data zips
- duplicate the source `FTL.app`
- patch the duplicate app's `ftl.dat`
- install `Hyperspace.command` and the matching macOS `.dylib`
- switch `CFBundleExecutable` to `Hyperspace.command`
- re-sign the resulting bundle with ad-hoc `codesign`

## Safety

- the source app is not modified
- the installer refuses to overwrite an existing output app
- large downloads and temporary files live under `tmp/`, which is ignored by Git

## Verified result

This workflow was validated against a real local Mac `FTL 1.6.13` app bundle and confirmed to reach the `FTL: Multiverse` main menu.
