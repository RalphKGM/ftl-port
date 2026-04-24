# ftl-port

This repo tracks the native macOS `FTL: Hyperspace` path, with a focus on turning upstream macOS support into a release process that is easy to verify and ship.

## Current status

The old "borderline impossible" reputation is outdated.

Upstream `FTL-Hyperspace` already contains a native macOS target in source:

- `FTLGameMacOSAMD64.cpp` and `FTLGameMacOSAMD64.h`
- `APPLE` branches in `CMakeLists.txt`
- darwin toolchains, triplets, build scripts, tests, and GitHub Actions workflows
- a native Mac installation guide under `Release Files/MacOS/README.txt`

What is still unclear from the public release flow is packaging: the latest upstream release asset we audited, `v1.21.1` published on `2026-01-25`, ships a single zip containing Windows and Linux payloads, but not the packaged macOS payload.

That means the main problem appears to be:

1. verify the current macOS build path end to end
2. package the native macOS artifacts consistently
3. publish them as part of normal releases

## Repo contents

- `to-do.md`: working checklist for the native macOS track
- `docs/upstream-status.md`: notes from the upstream audit
- `scripts/audit_upstream_macos.sh`: quick audit of source support and release packaging

## Usage

Run the audit:

```bash
./scripts/audit_upstream_macos.sh
```

## Scope

This repo is currently a coordination and verification workspace.
It is not yet a full fork of upstream `FTL-Hyperspace`, and it does not pretend the native macOS path is already fully shipped.
