Goal: turn the current upstream native macOS Hyperspace work into a reproducible, shippable, verifiable release path for the native FTL Mac app.

Done now

- [x] Initialize this repo and connect `origin` to `https://github.com/RalphKGM/ftl-port.git`
- [x] Audit upstream source layout for native macOS support
- [x] Confirm upstream already contains:
  - `FTLGameMacOSAMD64.cpp/.h`
  - `APPLE` branches in `CMakeLists.txt`
  - darwin triplets/toolchains/build scripts
  - macOS GitHub Actions workflows
  - a native Mac install guide in `Release Files/MacOS/README.txt`
- [x] Confirm latest release `v1.21.1` still ships only a cross-platform zip with Windows and Linux payloads, not the packaged macOS payload
- [x] Add local documentation and an audit script so the current state is reproducible

First half completed in this turn

- [x] Write a repo `README.md` with the current native macOS status
- [x] Add `docs/upstream-status.md` with concrete evidence and links
- [x] Add `scripts/audit_upstream_macos.sh` to verify source support versus release packaging
- [x] Add `.gitignore` for downloaded artifacts and scratch space

Second half to do next

- [x] Reproduce the upstream macOS build path on a real macOS machine or clean macOS CI run
- [x] Isolate the current macOS build blocker to `sdl2` `2.0.22#1` and prepare a pinned local overlay patch for the macOS HIDAPI C89 compile failure
- [x] Remove SDL2's `-Werror=declaration-after-statement` gate for the macOS overlay build so current AppleClang can get through the old Darwin sources
- [x] Finish SDL2 on Apple Silicon hosts by forcing the Objective-C compilation path to stay `x86_64` instead of mixing `arm64` and `x86_64` objects in `libSDL2d.a`
- [x] Build both `Hyperspace.1.6.12.amd64.dylib` and `Hyperspace.1.6.13.amd64.dylib`
- [x] Adapt a local darwin smoke-test entrypoint for real FTL binaries
- [x] Produce the missing `FTL.Hyperspace.<version>-MacOS.zip` package
- [ ] Validate native installation into `FTL.app` for Steam 1.6.13 and GOG 1.6.12/1.6.13 if supported
- [ ] Upstream the packaging or release fixes so macOS artifacts are published with normal releases

Open questions

- [x] Is the latest source branch fully green for macOS, or are the workflows/build scripts newer than the last shipped public release?
- [ ] Is Apple Silicon support meant to be Rosetta-only for the game binary with x86_64 Hyperspace, or is there a longer-term arm64 plan?
- [ ] Which exact macOS versions are considered supported by the current upstream toolchain?

Current answers

- [x] Source is ahead of the latest shipped public release: local checkout metadata is `1.22.0`, while the latest public release audited was `v1.21.1`
- [ ] A real local `FTL.app` is still required for final install validation and smoke testing
