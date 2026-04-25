#!/bin/bash

COMMON_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$COMMON_DIR/.." && pwd)

# shellcheck source=./versions.sh
source "$COMMON_DIR/versions.sh"

STAGE_ROOT="$REPO_ROOT/tmp/native-macos-multiverse"
DOWNLOAD_DIR="$STAGE_ROOT/downloads"
FTLMAN_DIR="$STAGE_ROOT/ftlman"

FTLMAN_AARCH64_URL="https://github.com/afishhh/ftlman/releases/download/${FTLMAN_VERSION}/ftlman-aarch64-apple-darwin.tar.gz"
FTLMAN_X86_64_URL="https://github.com/afishhh/ftlman/releases/download/${FTLMAN_VERSION}/ftlman-x86_64-apple-darwin.tar.gz"

MV_ASSETS_URL="https://github.com/FTL-Multiverse-Team/FTL-Multiverse-Releases/releases/download/${MV_ASSETS_VERSION}/${MV_ASSETS_FILE}"
MV_DATA_URL="https://github.com/FTL-Multiverse-Team/FTL-Multiverse-Releases/releases/download/${MV_DATA_VERSION}/${MV_DATA_FILE}"

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

prepare_ftlman() {
    local arch tarball url version_stamp

    mkdir -p "$DOWNLOAD_DIR" "$FTLMAN_DIR"
    version_stamp="$FTLMAN_DIR/.version"

    arch="$(uname -m)"
    case "$arch" in
        arm64)
            url="$FTLMAN_AARCH64_URL"
            tarball="$DOWNLOAD_DIR/ftlman-${FTLMAN_VERSION}-aarch64-apple-darwin.tar.gz"
            ;;
        x86_64)
            url="$FTLMAN_X86_64_URL"
            tarball="$DOWNLOAD_DIR/ftlman-${FTLMAN_VERSION}-x86_64-apple-darwin.tar.gz"
            ;;
        *)
            echo "Unsupported host architecture: $arch" >&2
            exit 1
            ;;
    esac

    download_file "$url" "$tarball"

    if [ ! -x "$FTLMAN_DIR/ftlman/ftlman" ] || [ ! -f "$version_stamp" ] || [ "$(cat "$version_stamp")" != "$FTLMAN_VERSION" ]; then
        rm -rf "$FTLMAN_DIR"
        mkdir -p "$FTLMAN_DIR"
        tar -xzf "$tarball" -C "$FTLMAN_DIR"
        printf '%s\n' "$FTLMAN_VERSION" > "$version_stamp"
    fi

    FTLMAN_BIN="$FTLMAN_DIR/ftlman/ftlman"
    if [ ! -x "$FTLMAN_BIN" ]; then
        echo "Failed to prepare ftlman CLI at $FTLMAN_BIN" >&2
        exit 1
    fi
}

set_bundle_executable() {
    local plist_path="$1"
    local value="$2"

    if /usr/libexec/PlistBuddy -c "Set :CFBundleExecutable $value" "$plist_path" >/dev/null 2>&1; then
        return
    fi

    /usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string $value" "$plist_path"
}

resign_app() {
    local app_path="$1"

    codesign -f -s - --timestamp=none --all-architectures --deep "$app_path"
    codesign --verify --deep --strict "$app_path"
}
