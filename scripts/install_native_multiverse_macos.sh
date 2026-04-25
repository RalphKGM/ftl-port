#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

usage() {
    cat >&2 <<'EOF'
Usage: install_native_multiverse_macos.sh /path/to/FTL.app [/path/to/output.app]

Defaults:
  output.app defaults to a sibling app named "FTL Multiverse.app"

Behavior:
  - builds the pinned native macOS Hyperspace dylibs from source
  - downloads the validated Multiverse 5.5/5.5.1 release files
  - patches a duplicate app bundle
  - installs the native Hyperspace launcher into that bundle
  - re-signs the bundle for macOS launch

Safety:
  - the source app is never modified
  - the script refuses to overwrite an existing output app
EOF
    exit 1
}

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    usage
fi

SOURCE_APP="$1"
if [ ! -d "$SOURCE_APP" ]; then
    echo "Source app does not exist: $SOURCE_APP" >&2
    exit 1
fi

SOURCE_APP="$(cd "$(dirname "$SOURCE_APP")" && pwd)/$(basename "$SOURCE_APP")"

if [ $# -eq 2 ]; then
    OUTPUT_APP="$2"
else
    OUTPUT_APP="$(dirname "$SOURCE_APP")/FTL Multiverse.app"
fi
OUTPUT_APP="$(cd "$(dirname "$OUTPUT_APP")" && pwd)/$(basename "$OUTPUT_APP")"

if [ "$SOURCE_APP" = "$OUTPUT_APP" ]; then
    echo "Output app must be different from source app" >&2
    exit 1
fi

if [ -e "$OUTPUT_APP" ]; then
    echo "Output app already exists: $OUTPUT_APP" >&2
    echo "Move or delete it first, or choose a different output path." >&2
    exit 1
fi

INFO_PLIST="$SOURCE_APP/Contents/Info.plist"
FTL_BINARY="$SOURCE_APP/Contents/MacOS/FTL"
RESOURCE_DIR="$SOURCE_APP/Contents/Resources"

if [ ! -f "$INFO_PLIST" ] || [ ! -f "$FTL_BINARY" ] || [ ! -d "$RESOURCE_DIR" ]; then
    echo "Source app does not look like a valid FTL bundle: $SOURCE_APP" >&2
    exit 1
fi

FTL_VERSION="$(/usr/bin/plutil -extract CFBundleVersion raw -o - "$INFO_PLIST" 2>/dev/null || true)"
case "$FTL_VERSION" in
    1.6.12|1.6.13)
        ;;
    *)
        echo "Unsupported FTL version: ${FTL_VERSION:-unknown}" >&2
        echo "Expected 1.6.12 or 1.6.13" >&2
        exit 1
        ;;
esac

MV_ASSETS_ZIP="$DOWNLOAD_DIR/$MV_ASSETS_FILE"
MV_DATA_ZIP="$DOWNLOAD_DIR/$MV_DATA_FILE"

prepare_ftlman
download_file "$MV_ASSETS_URL" "$MV_ASSETS_ZIP"
download_file "$MV_DATA_URL" "$MV_DATA_ZIP"

log "Building native macOS Hyperspace artifacts..."
"$REPO_ROOT/scripts/build_upstream_native_macos.sh"

UPSTREAM_ROOT="$REPO_ROOT/upstream/FTL-Hyperspace"
HS_COMMAND="$UPSTREAM_ROOT/build-package-macos/MacOS/Hyperspace.command"
HS_DYLIB="$UPSTREAM_ROOT/build-darwin-${FTL_VERSION}-release/Hyperspace.${FTL_VERSION}.amd64.dylib"

if [ ! -f "$HS_COMMAND" ] || [ ! -f "$HS_DYLIB" ]; then
    echo "Missing built Hyperspace launcher artifacts" >&2
    echo "Expected:" >&2
    echo "  $HS_COMMAND" >&2
    echo "  $HS_DYLIB" >&2
    exit 1
fi

log "Creating app copy at $OUTPUT_APP"
ditto "$SOURCE_APP" "$OUTPUT_APP"

log "Patching Multiverse data into app bundle..."
"$FTLMAN_BIN" patch \
    -d "$OUTPUT_APP/Contents/Resources" \
    "$MV_ASSETS_ZIP" \
    "$MV_DATA_ZIP"

find "$OUTPUT_APP/Contents/MacOS" -maxdepth 1 \
    \( -name 'Hyperspace.command' -o -name 'Hyperspace.*.amd64.dylib' \) -delete

cp "$HS_COMMAND" "$OUTPUT_APP/Contents/MacOS/"
cp "$HS_DYLIB" "$OUTPUT_APP/Contents/MacOS/"
chmod 755 "$OUTPUT_APP/Contents/MacOS/Hyperspace.command"

set_bundle_executable "$OUTPUT_APP/Contents/Info.plist" "Hyperspace.command"

log "Re-signing app bundle..."
resign_app "$OUTPUT_APP"

log ""
log "Done."
log "Playable app: $OUTPUT_APP"
log "Original app left untouched: $SOURCE_APP"
