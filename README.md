# ftl-port

This repo tracks the native macOS `FTL: Hyperspace` path, with a focus on turning upstream macOS support into a release process that is easy to verify and ship.

## Current status

The old "borderline impossible" reputation is outdated.

Upstream `FTL-Hyperspace` already contains a native macOS target in source:

- `FTLGameMacOSAMD64.cpp` and `FTLGameMacOSAMD64.h`
- `APPLE` branches in `CMakeLists.txt`
- darwin toolchains, triplets, build scripts, tests, and GitHub Actions workflows
- a native Mac installation guide under `Release Files/MacOS/README.txt`

As of this workspace run on `2026-04-25` in `Asia/Manila`, we have now proven that the native macOS release path builds on Apple Silicon for `x86_64`/Rosetta-targeted FTL:

- `Hyperspace.1.6.12.amd64.dylib` builds successfully
- `Hyperspace.1.6.13.amd64.dylib` builds successfully
- upstream `buildscripts/ci/package-macos.sh` produces `FTL.Hyperspace.1.22.0-MacOS.zip`

The main public-release gap is still packaging and publishing upstream: the latest upstream release asset we audited, `v1.21.1` published on `2026-01-25`, ships a single zip containing Windows and Linux payloads, but not the dedicated macOS zip that the source tree already knows how to build.

That means the main remaining work is:

1. validate the native package against a real local `FTL.app`
2. confirm the install flow for Steam and GOG app bundles
3. upstream the macOS release packaging so normal releases publish it

## Repo contents

- `to-do.md`: working checklist for the native macOS track
- `docs/upstream-status.md`: notes from the upstream audit
- `docs/native-macos-multiverse.md`: shareable native macOS Multiverse workflow
- `scripts/audit_upstream_macos.sh`: quick audit of source support and release packaging
- `scripts/build_upstream_native_macos.sh`: build both macOS dylibs and package the current source version
- `scripts/install_native_multiverse_macos.sh`: one-shot install of native Mac Multiverse into a duplicated `FTL.app`
- `scripts/run_upstream_native_macos_smoke_test.sh`: run the upstream darwin smoke test against a real `FTL.app`

## Usage

Run the audit:

```bash
./scripts/audit_upstream_macos.sh
```

Build and package native macOS artifacts:

```bash
./scripts/build_upstream_native_macos.sh
```

Install native macOS Multiverse into a duplicate app bundle:

```bash
./scripts/install_native_multiverse_macos.sh "/path/to/FTL.app"
```

Smoke-test against a real local app bundle when available:

```bash
./scripts/run_upstream_native_macos_smoke_test.sh "/path/to/FTL.app"
```

## Scope

This repo is still a coordination and verification workspace rather than a full upstream fork.
The native macOS build/package path is now working locally, but the final install validation step still needs a real `FTL.app`.
