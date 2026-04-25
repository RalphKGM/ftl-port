#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
UPSTREAM_ROOT="$REPO_ROOT/upstream/FTL-Hyperspace"

usage() {
    echo "Usage: $0 /path/to/FTL.app [test_name]" >&2
    echo "   or: $0 /path/to/FTL.app/Contents/MacOS/FTL [test_name]" >&2
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

INPUT_PATH="$1"
TEST_NAME="${2:-}"

if [ ! -e "$INPUT_PATH" ]; then
    echo "Missing FTL path: $INPUT_PATH" >&2
    exit 1
fi

if [[ "$INPUT_PATH" == *.app ]]; then
    APP_PATH="$INPUT_PATH"
    FTL_BINARY_PATH="$APP_PATH/Contents/MacOS/FTL"
else
    FTL_BINARY_PATH="$INPUT_PATH"
    APP_PATH="$(cd "$(dirname "$FTL_BINARY_PATH")/../.." && pwd)"
fi

INFO_PLIST_PATH="$APP_PATH/Contents/Info.plist"
if [ ! -f "$INFO_PLIST_PATH" ]; then
    echo "Could not locate Info.plist for app at $APP_PATH" >&2
    exit 1
fi

if [ ! -f "$FTL_BINARY_PATH" ]; then
    echo "Could not locate FTL binary at $FTL_BINARY_PATH" >&2
    exit 1
fi

FTL_VERSION="$(/usr/bin/plutil -extract CFBundleVersion raw -o - "$INFO_PLIST_PATH" 2>/dev/null || true)"
case "$FTL_VERSION" in
    1.6.12|1.6.13)
        ;;
    *)
        echo "Unsupported or undetected FTL version: ${FTL_VERSION:-unknown}" >&2
        exit 1
        ;;
esac

RELEASE_DYLIB="$UPSTREAM_ROOT/build-darwin-${FTL_VERSION}-release/Hyperspace.${FTL_VERSION}.amd64.dylib"
DEBUG_DYLIB="$UPSTREAM_ROOT/build-darwin-${FTL_VERSION}-debug/Hyperspace.${FTL_VERSION}.amd64.dylib"

if [ -f "$RELEASE_DYLIB" ]; then
    FTL_DYLIB_PATH="$RELEASE_DYLIB"
elif [ -f "$DEBUG_DYLIB" ]; then
    FTL_DYLIB_PATH="$DEBUG_DYLIB"
else
    echo "No built Hyperspace dylib found for FTL ${FTL_VERSION}" >&2
    exit 1
fi

cd "$UPSTREAM_ROOT"
"$UPSTREAM_ROOT/tests/run_test_darwin.sh" "$FTL_DYLIB_PATH" "$FTL_BINARY_PATH" "$TEST_NAME"
