#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
UPSTREAM_ROOT="$REPO_ROOT/upstream/FTL-Hyperspace"
METADATA_PATH="$UPSTREAM_ROOT/Mod Files/mod-appendix/metadata.xml"
CMAKE_PATH="$UPSTREAM_ROOT/CMakeLists.txt"
HYPERSPACE_REPO_URL="${HYPERSPACE_REPO_URL:-https://github.com/FTL-Hyperspace/FTL-Hyperspace.git}"
HYPERSPACE_REF="${HYPERSPACE_REF:-55f0d96a4746e4ac6fc67110070a41264321437a}"

clone_upstream_if_missing() {
    if [ -d "$UPSTREAM_ROOT/.git" ]; then
        return
    fi

    mkdir -p "$(dirname "$UPSTREAM_ROOT")"
    echo "Cloning upstream Hyperspace into $UPSTREAM_ROOT"
    git clone --recursive "$HYPERSPACE_REPO_URL" "$UPSTREAM_ROOT"
    git -C "$UPSTREAM_ROOT" checkout "$HYPERSPACE_REF"
    git -C "$UPSTREAM_ROOT" submodule update --init --recursive
}

clone_upstream_if_missing

if [ ! -f "$METADATA_PATH" ]; then
    echo "Missing upstream metadata at $METADATA_PATH" >&2
    exit 1
fi

if [ ! -f "$CMAKE_PATH" ]; then
    echo "Missing upstream CMake file at $CMAKE_PATH" >&2
    exit 1
fi

if [ "$(git -C "$UPSTREAM_ROOT" rev-parse HEAD)" != "$HYPERSPACE_REF" ]; then
    echo "Warning: upstream checkout is not at pinned ref $HYPERSPACE_REF" >&2
    echo "Current ref: $(git -C "$UPSTREAM_ROOT" rev-parse HEAD)" >&2
fi

ensure_iconv_link_fix() {
    if ! grep -q 'find_package(Iconv REQUIRED)' "$CMAKE_PATH"; then
        perl -0pi -e 's/find_package\(ZLIB REQUIRED\)\n/find_package(ZLIB REQUIRED)\nfind_package(Iconv REQUIRED)\n/' "$CMAKE_PATH"
    fi

    if ! grep -q 'Iconv::Iconv' "$CMAKE_PATH"; then
        perl -0pi -e 's/ZLIB::ZLIB\n/ZLIB::ZLIB\n    Iconv::Iconv\n/' "$CMAKE_PATH"
    fi
}

read_source_version() {
    sed -n 's:.*<!\[CDATA\[ *\([^ ]*\) *\]\]></version>.*:\1:p' "$METADATA_PATH" | head -n 1
}

build_variant() {
    local version="$1"
    echo "=== Building macOS Hyperspace for FTL ${version} ==="
    "$UPSTREAM_ROOT/buildscripts/darwin-${version}/build-releaseonly.sh"
}

ensure_iconv_link_fix

VERSION="$(read_source_version)"
if [ -z "$VERSION" ]; then
    echo "Unable to determine source version from $METADATA_PATH" >&2
    exit 1
fi

export VCPKG_DISABLE_METRICS=1
export VCPKG_OVERLAY_PORTS="$REPO_ROOT/overlays"

build_variant 1.6.13
build_variant 1.6.12

echo "=== Packaging macOS release ${VERSION} ==="
"$UPSTREAM_ROOT/buildscripts/ci/package-macos.sh" "$VERSION"

echo ""
echo "Built artifacts:"
echo "  $UPSTREAM_ROOT/build-darwin-1.6.12-release/Hyperspace.1.6.12.amd64.dylib"
echo "  $UPSTREAM_ROOT/build-darwin-1.6.13-release/Hyperspace.1.6.13.amd64.dylib"
echo "  $UPSTREAM_ROOT/FTL.Hyperspace.${VERSION}-MacOS.zip"
