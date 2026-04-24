#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
UPSTREAM_ROOT="$REPO_ROOT/upstream/FTL-Hyperspace"
BUILD_DIR="$UPSTREAM_ROOT/build-darwin-1.6.13-release"

if [ ! -d "$UPSTREAM_ROOT" ]; then
    echo "Missing upstream checkout at $UPSTREAM_ROOT" >&2
    exit 1
fi

rm -rf "$BUILD_DIR"

export VCPKG_DISABLE_METRICS=1
export VCPKG_OVERLAY_PORTS="$REPO_ROOT/overlays"

"$UPSTREAM_ROOT/buildscripts/darwin-1.6.13/build-releaseonly.sh"
