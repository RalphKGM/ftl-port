#!/usr/bin/env bash

set -euo pipefail

repo="FTL-Hyperspace/FTL-Hyperspace"
api_root="https://api.github.com/repos/${repo}"
raw_root="https://raw.githubusercontent.com/FTL-Hyperspace/FTL-Hyperspace/refs/heads/master"
tmp_dir="${TMPDIR:-/tmp}/ftl-port-audit"
zip_path="${tmp_dir}/latest.zip"

mkdir -p "${tmp_dir}"

need_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Missing required command: $1" >&2
        exit 1
    fi
}

need_cmd curl
need_cmd jq
need_cmd unzip

echo "== Upstream source checks =="

check_raw_contains() {
    local path="$1"
    local pattern="$2"
    local label="$3"

    if curl -fsSL "${raw_root}/${path}" | grep -Fq "${pattern}"; then
        echo "[ok] ${label}"
    else
        echo "[missing] ${label}"
        return 1
    fi
}

check_raw_contains "CMakeLists.txt" "if(APPLE)" "CMake has APPLE branch"
check_raw_contains "FTLGame.cpp" "FTLGameMacOSAMD64.cpp" "FTLGame.cpp includes macOS translation unit"
check_raw_contains "FTLGame.h" "FTLGameMacOSAMD64.h" "FTLGame.h includes macOS header"
check_raw_contains ".github/workflows/build-macos.yml" "Build macOS" "macOS build workflow exists"
check_raw_contains ".github/workflows/release-macos.yml" "Release macOS" "macOS release workflow exists"
check_raw_contains "buildscripts/ci/package-macos.sh" "FTL.Hyperspace" "macOS packaging script exists"

echo
echo "== Latest release metadata =="

release_json="$(curl -fsSL "${api_root}/releases/latest")"
tag_name="$(printf '%s' "${release_json}" | jq -r '.tag_name')"
published_at="$(printf '%s' "${release_json}" | jq -r '.published_at')"

echo "tag: ${tag_name}"
echo "published_at: ${published_at}"
echo "assets:"
printf '%s' "${release_json}" | jq -r '.assets[].name' | sed 's/^/  - /'

asset_url="$(printf '%s' "${release_json}" | jq -r '.assets[0].browser_download_url')"
if [ -z "${asset_url}" ] || [ "${asset_url}" = "null" ]; then
    echo "No downloadable release asset found." >&2
    exit 1
fi

echo
echo "== Inspecting latest release zip =="

curl -fL "${asset_url}" -o "${zip_path}" >/dev/null

has_macos_payload="no"
if zipinfo -1 "${zip_path}" | grep -Eq '(^MacOS/|Hyperspace\.command|Hyperspace\.[0-9.]+\.amd64\.dylib$)'; then
    has_macos_payload="yes"
fi

echo "macOS payload present in latest public zip: ${has_macos_payload}"

echo "matching entries:"
zipinfo -1 "${zip_path}" | grep -E '(^MacOS/|Hyperspace\.command|Hyperspace\.[0-9.]+\.amd64\.dylib$|^Linux/|^Windows )' || true

echo
if [ "${has_macos_payload}" = "yes" ]; then
    echo "Result: upstream source and latest public release both expose macOS payloads."
else
    echo "Result: upstream source exposes macOS support, but the latest public release zip does not include the packaged macOS payload."
fi
