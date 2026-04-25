#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

STAGE_ROOT="$REPO_ROOT/tmp/native-macos-multiverse"
DOWNLOAD_DIR="$STAGE_ROOT/downloads"
FTLMAN_DIR="$STAGE_ROOT/ftlman"

FTLMAN_VERSION="v0.7.2"
FTLMAN_AARCH64_URL="https://github.com/afishhh/ftlman/releases/download/${FTLMAN_VERSION}/ftlman-aarch64-apple-darwin.tar.gz"
FTLMAN_X86_64_URL="https://github.com/afishhh/ftlman/releases/download/${FTLMAN_VERSION}/ftlman-x86_64-apple-darwin.tar.gz"

MV_ASSETS_VERSION="v5.5"
MV_DATA_VERSION="v5.5.1"
MV_ASSETS_URL="https://github.com/FTL-Multiverse-Team/FTL-Multiverse-Releases/releases/download/${MV_ASSETS_VERSION}/Multiverse.5.5.-.Assets.Patch.above.Data.zip"
MV_DATA_URL="https://github.com/FTL-Multiverse-Team/FTL-Multiverse-Releases/releases/download/${MV_DATA_VERSION}/Multiverse.5.5.1.-.Data.zip"

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

log() {
    printf '%s\n' "$*"
}

download_file() {
    local url="$1"
    local dest="$2"

    if [ -f "$dest" ]; then
        return
    fi

    mkdir -p "$(dirname "$dest")"
    curl -L --fail --retry 3 --output "${dest}.part" "$url"
    mv "${dest}.part" "$dest"
}

set_bundle_executable() {
    local plist_path="$1"
    local value="$2"

    if /usr/libexec/PlistBuddy -c "Set :CFBundleExecutable $value" "$plist_path" >/dev/null 2>&1; then
        return
    fi

    /usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string $value" "$plist_path"
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

mkdir -p "$DOWNLOAD_DIR" "$FTLMAN_DIR"

ARCH="$(uname -m)"
case "$ARCH" in
    arm64)
        FTLMAN_URL="$FTLMAN_AARCH64_URL"
        FTLMAN_TARBALL="$DOWNLOAD_DIR/ftlman-aarch64-apple-darwin.tar.gz"
        ;;
    x86_64)
        FTLMAN_URL="$FTLMAN_X86_64_URL"
        FTLMAN_TARBALL="$DOWNLOAD_DIR/ftlman-x86_64-apple-darwin.tar.gz"
        ;;
    *)
        echo "Unsupported host architecture: $ARCH" >&2
        exit 1
        ;;
esac

MV_ASSETS_ZIP="$DOWNLOAD_DIR/Multiverse.5.5.-.Assets.Patch.above.Data.zip"
MV_DATA_ZIP="$DOWNLOAD_DIR/Multiverse.5.5.1.-.Data.zip"

download_file "$FTLMAN_URL" "$FTLMAN_TARBALL"
download_file "$MV_ASSETS_URL" "$MV_ASSETS_ZIP"
download_file "$MV_DATA_URL" "$MV_DATA_ZIP"

if [ ! -x "$FTLMAN_DIR/ftlman/ftlman" ]; then
    rm -rf "$FTLMAN_DIR"
    mkdir -p "$FTLMAN_DIR"
    tar -xzf "$FTLMAN_TARBALL" -C "$FTLMAN_DIR"
fi

FTLMAN_BIN="$FTLMAN_DIR/ftlman/ftlman"
if [ ! -x "$FTLMAN_BIN" ]; then
    echo "Failed to prepare ftlman CLI at $FTLMAN_BIN" >&2
    exit 1
fi

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
codesign -f -s - --timestamp=none --all-architectures --deep "$OUTPUT_APP"
codesign --verify --deep --strict "$OUTPUT_APP"

log ""
log "Done."
log "Playable app: $OUTPUT_APP"
log "Original app left untouched: $SOURCE_APP"
