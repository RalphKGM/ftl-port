# Upstream native macOS status

Audit date: `2026-04-24`

## Summary

Upstream `FTL-Hyperspace` already contains substantial native macOS support in source and build tooling, and this workspace has now reproduced the native macOS build/package path successfully on Apple Silicon for `x86_64` targets.

The strongest evidence is:

- `CMakeLists.txt` has explicit `if(APPLE)` handling
- `FTLGame.cpp` includes `FTLGameMacOSAMD64.cpp` for `__APPLE__`
- `FTLGame.h` includes `FTLGameMacOSAMD64.h` for `__APPLE__`
- the repo contains darwin triplets, toolchains, build scripts, tests, and GitHub Actions workflows
- `Release Files/MacOS/README.txt` documents native installation into `FTL.app`
- local builds succeeded for:
  - `Hyperspace.1.6.12.amd64.dylib`
  - `Hyperspace.1.6.13.amd64.dylib`
- local packaging succeeded for:
  - `FTL.Hyperspace.1.22.0-MacOS.zip`

The main gap now appears to be release publishing, not feasibility:

- latest upstream release: `v1.21.1`
- published: `2026-01-25T19:23:08Z`
- public assets in the latest release: only `FTL.Hyperspace.1.21.1.zip`
- contents of that zip, as audited locally, include Windows and Linux payloads but no packaged macOS payload
- current source metadata in this checkout is already at `1.22.0`

So the working hypothesis is that the macOS port exists upstream in source and builds locally, but the dedicated macOS artifact is not being published as part of the normal public release flow.

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

### Local build reproduction

On this workspace:

- host OS: macOS on Apple Silicon
- produced dylibs:
  - `build-darwin-1.6.12-release/Hyperspace.1.6.12.amd64.dylib`
  - `build-darwin-1.6.13-release/Hyperspace.1.6.13.amd64.dylib`
- packaged artifact:
  - `FTL.Hyperspace.1.22.0-MacOS.zip`

Two local fixes were needed to get there:

- an SDL2 overlay port to make the older Darwin/HIDAPI sources build cleanly and consistently as `x86_64`
- an `Iconv` link fix in upstream `CMakeLists.txt` so the final macOS dylib link resolves `iconv_*`

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

### Source-ahead-of-release signal

The current upstream checkout used here reports `1.22.0` in `Mod Files/mod-appendix/metadata.xml`, while the latest public release audited above is `v1.21.1`.

That strongly suggests the source branch is ahead of the latest published artifact set.

## Likely next engineering steps

1. Validate the generated `.dylib` files against a real local `FTL.app`.
2. Run the darwin test scripts against Steam `1.6.13` and GOG `1.6.12`/`1.6.13` if available.
3. Upstream the SDL2 macOS overlay and `Iconv` link fix in a cleaner form.
4. Wire the dedicated macOS zip into the public release path so releases publish:
   - `FTL.Hyperspace.<version>-MacOS.zip`
5. Decide whether to:
   - contribute fixes directly upstream, or
   - maintain a downstream packaging repo that publishes macOS artifacts.

## References

- Upstream repo: `https://github.com/FTL-Hyperspace/FTL-Hyperspace`
- Latest release API: `https://api.github.com/repos/FTL-Hyperspace/FTL-Hyperspace/releases/latest`
