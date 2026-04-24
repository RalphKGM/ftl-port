# Upstream native macOS status

Audit date: `2026-04-24`

## Summary

Upstream `FTL-Hyperspace` already contains substantial native macOS support in source and build tooling.

The strongest evidence is:

- `CMakeLists.txt` has explicit `if(APPLE)` handling
- `FTLGame.cpp` includes `FTLGameMacOSAMD64.cpp` for `__APPLE__`
- `FTLGame.h` includes `FTLGameMacOSAMD64.h` for `__APPLE__`
- the repo contains darwin triplets, toolchains, build scripts, tests, and GitHub Actions workflows
- `Release Files/MacOS/README.txt` documents native installation into `FTL.app`

The main gap found during this audit is release packaging:

- latest upstream release: `v1.21.1`
- published: `2026-01-25T19:23:08Z`
- public assets in the latest release: only `FTL.Hyperspace.1.21.1.zip`
- contents of that zip, as audited locally, include Windows and Linux payloads but no packaged macOS payload

So the working hypothesis is that the macOS port exists upstream in source, but the public release path is incomplete or not yet wired into the main artifact users download.

## Evidence

### Source-level macOS target

- `CMakeLists.txt`
  - sets mac-specific SDL2 paths
  - links Apple frameworks
  - raises C++ standard to `c++14` on macOS
- `FTLGame.cpp`
  - includes `FTLGameMacOSAMD64.cpp` for `__APPLE__`
- `FTLGame.h`
  - includes `FTLGameMacOSAMD64.h` for `__APPLE__`

### Build and release pipeline

Upstream tree contains:

- `.devcontainer/toolchains/amd64-darwin-ftl.cmake`
- `.devcontainer/triplets/amd64-darwin-ftl.cmake`
- `buildscripts/buildall-darwin.sh`
- `buildscripts/buildall-darwin-release-only.sh`
- `.github/workflows/build-macos.yml`
- `.github/workflows/release-macos.yml`
- `buildscripts/ci/setup-macos.sh`
- `buildscripts/ci/package-macos.sh`
- darwin test runners under `tests/` and `libzhlgen/`

### Native installation docs

`Release Files/MacOS/README.txt` describes:

- editing `FTL.app/Contents/Info.plist`
- switching `CFBundleExecutable` to `Hyperspace.command`
- copying `Hyperspace.command` and a matching `Hyperspace.*.dylib`
- using `ftlman` against `FTL.app/Contents/Resources/ftl.dat`
- re-signing the app with `codesign`

That is a native Mac app patching flow, not a Wine wrapper flow.

### Release mismatch

The latest release asset was inspected via GitHub API and by listing the zip contents.

Findings:

- release tag: `v1.21.1`
- asset list:
  - `FTL.Hyperspace.1.21.1.zip`
- inspected zip contents include:
  - `Linux/Hyperspace.1.6.12.amd64.so`
  - `Linux/Hyperspace.1.6.13.amd64.so`
  - `Windows - Extract these files into where FTLGame.exe is/Hyperspace.dll`
  - downgrade patch files
- no `MacOS/` directory
- no `Hyperspace.command`
- no `Hyperspace.*.dylib`

## Likely next engineering steps

1. Reproduce the upstream macOS build locally or in CI.
2. Confirm the generated `.dylib` names and compatibility against real FTL Mac binaries.
3. Run the darwin test scripts and note any failures.
4. Generate the dedicated macOS package via `buildscripts/ci/package-macos.sh`.
5. Decide whether to:
   - contribute fixes directly upstream, or
   - maintain a downstream packaging repo that publishes macOS artifacts.

## References

- Upstream repo: `https://github.com/FTL-Hyperspace/FTL-Hyperspace`
- Latest release API: `https://api.github.com/repos/FTL-Hyperspace/FTL-Hyperspace/releases/latest`
