# Troubleshooting

This repo ships a validated native macOS `Hyperspace + Multiverse` workflow, but it is still a narrower path than the usual Windows setup. If something breaks, start here.

## Common cases

### The app will not open

- Re-sign the app:

```bash
codesign -f -s - --timestamp=none --all-architectures --deep "/path/to/FTL Multiverse.app"
```

- If Finder still blocks launch, try starting the launcher directly in Terminal:

```bash
"/path/to/FTL Multiverse.app/Contents/MacOS/Hyperspace.command"
```

That usually gives a more useful error than a silent Finder failure.

### I want to add more mods

Use:

```bash
./scripts/add_mods_to_macos_app.sh "/path/to/FTL Multiverse.app" /path/to/mod1.ftl [/path/to/mod2.ftl ...]
```

Notes:

- the target app is modified in place
- mod order matches the order you pass on the command line
- the script keeps a one-time backup at `ftl.dat.before-extra-mods`
- not every mod is compatible with `Hyperspace` and `Multiverse`

### A new Multiverse update came out

Do not assume a fresh update is automatically safe with the pinned native Mac path.

Use:

```bash
./scripts/update_pinned_versions.sh --show
```

Then update the pins, rebuild, and re-test before treating the new combo as stable:

```bash
./scripts/update_pinned_versions.sh \
  --mv-assets-version "NEW_ASSETS_TAG" \
  --mv-assets-file "NEW_ASSETS_FILE.zip" \
  --mv-data-version "NEW_DATA_TAG" \
  --mv-data-file "NEW_DATA_FILE.zip"
./scripts/build_upstream_native_macos.sh
./scripts/run_upstream_native_macos_smoke_test.sh "/path/to/FTL.app"
```

### Builds are acting weird after a version change

Clear the local caches and rebuild:

```bash
rm -rf tmp upstream
./scripts/build_upstream_native_macos.sh
```

### The game launches but behaves strangely

Possible causes:

- a new `Multiverse` release changed assumptions
- an extra mod conflicts with `Multiverse`
- native Mac `Hyperspace` behavior differs from Windows
- cached build artifacts do not match the current version pins

Good first steps:

1. Try the base install without extra mods.
2. Rebuild from a clean `tmp/` and `upstream/`.
3. Launch `Hyperspace.command` from Terminal to capture output.

## Known limitations

- This repo is pinned to the versions in [scripts/versions.sh](/Users/ralph/projects/ftl-mv/scripts/versions.sh).
- The validated game versions are `FTL 1.6.12` and `1.6.13`.
- Extra mods are best-effort only.
- Native macOS `Hyperspace` is real and working here, but it is still less battle-tested than the Windows route.

## When reporting bugs

Include:

- your macOS version
- whether you are on Apple Silicon or Intel
- your FTL version
- the repo commit you used
- whether you used extra mods
- the exact command you ran
- any Terminal output from `Hyperspace.command`
