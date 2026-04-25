#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
VERSION_FILE="$SCRIPT_DIR/versions.sh"

# shellcheck source=./versions.sh
source "$VERSION_FILE"

usage() {
    cat >&2 <<'EOF'
Usage:
  update_pinned_versions.sh --show
  update_pinned_versions.sh [options]

Options:
  --hyperspace-ref SHA
  --ftlman-version VERSION
  --mv-assets-version VERSION
  --mv-assets-file FILENAME
  --mv-data-version VERSION
  --mv-data-file FILENAME

Examples:
  ./scripts/update_pinned_versions.sh --show
  ./scripts/update_pinned_versions.sh \
    --mv-assets-version v5.6 \
    --mv-assets-file "Multiverse.5.6.-.Assets.Patch.above.Data.zip" \
    --mv-data-version v5.6 \
    --mv-data-file "Multiverse.5.6.-.Data.zip"
EOF
    exit 1
}

show_versions() {
    cat <<EOF
HYPERSPACE_REF=$HYPERSPACE_REF
FTLMAN_VERSION=$FTLMAN_VERSION
MV_ASSETS_VERSION=$MV_ASSETS_VERSION
MV_ASSETS_FILE=$MV_ASSETS_FILE
MV_DATA_VERSION=$MV_DATA_VERSION
MV_DATA_FILE=$MV_DATA_FILE
EOF
}

escape_replacement() {
    printf '%s' "$1" | sed -e 's/[\\/&]/\\&/g'
}

require_value() {
    local option="$1"

    if [ $# -lt 2 ] || [ -z "${2:-}" ]; then
        echo "Missing value for $option" >&2
        exit 1
    fi
}

replace_var() {
    local key="$1"
    local value="$2"
    local escaped

    escaped="$(escape_replacement "$value")"
    perl -0pi -e "s/^${key}=\".*\"$/${key}=\"${escaped}\"/m" "$VERSION_FILE"
}

if [ $# -eq 0 ]; then
    usage
fi

SHOW_ONLY=0
UPDATED=0

while [ $# -gt 0 ]; do
    case "$1" in
        --show)
            SHOW_ONLY=1
            shift
            ;;
        --hyperspace-ref)
            require_value "$1" "${2:-}"
            replace_var "HYPERSPACE_REF" "$2"
            UPDATED=1
            shift 2
            ;;
        --ftlman-version)
            require_value "$1" "${2:-}"
            replace_var "FTLMAN_VERSION" "$2"
            UPDATED=1
            shift 2
            ;;
        --mv-assets-version)
            require_value "$1" "${2:-}"
            replace_var "MV_ASSETS_VERSION" "$2"
            UPDATED=1
            shift 2
            ;;
        --mv-assets-file)
            require_value "$1" "${2:-}"
            replace_var "MV_ASSETS_FILE" "$2"
            UPDATED=1
            shift 2
            ;;
        --mv-data-version)
            require_value "$1" "${2:-}"
            replace_var "MV_DATA_VERSION" "$2"
            UPDATED=1
            shift 2
            ;;
        --mv-data-file)
            require_value "$1" "${2:-}"
            replace_var "MV_DATA_FILE" "$2"
            UPDATED=1
            shift 2
            ;;
        --help|-h)
            usage
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            ;;
    esac
done

if [ "$SHOW_ONLY" -eq 1 ] && [ "$UPDATED" -eq 0 ]; then
    show_versions
    exit 0
fi

if [ "$UPDATED" -eq 0 ]; then
    usage
fi

# shellcheck source=./versions.sh
source "$VERSION_FILE"

echo "Updated pinned versions in $VERSION_FILE"
show_versions
echo ""
echo "Next steps:"
echo "  1. Run ./scripts/build_upstream_native_macos.sh"
echo "  2. Run ./scripts/run_upstream_native_macos_smoke_test.sh /path/to/FTL.app"
echo "  3. Reinstall or repatch your app once the new pins are validated"
