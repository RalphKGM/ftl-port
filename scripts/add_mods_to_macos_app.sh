#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

usage() {
    cat >&2 <<'EOF'
Usage: add_mods_to_macos_app.sh /path/to/FTL\ Multiverse.app /path/to/mod1.ftl [/path/to/mod2.ftl ...]

Behavior:
  - patches extra mods into an existing app bundle in the order provided
  - keeps a one-time backup of the pre-extra-mods ftl.dat as ftl.dat.before-extra-mods
  - re-signs the app after patching

Notes:
  - this modifies the target app in place
  - mod load order matches the order of arguments
EOF
    exit 1
}

if [ $# -lt 2 ]; then
    usage
fi

TARGET_APP="$1"
shift

if [ ! -d "$TARGET_APP" ]; then
    echo "Target app does not exist: $TARGET_APP" >&2
    exit 1
fi

TARGET_APP="$(cd "$(dirname "$TARGET_APP")" && pwd)/$(basename "$TARGET_APP")"
RESOURCE_DIR="$TARGET_APP/Contents/Resources"
INFO_PLIST="$TARGET_APP/Contents/Info.plist"
FTL_DAT="$RESOURCE_DIR/ftl.dat"
BACKUP_DAT="$RESOURCE_DIR/ftl.dat.before-extra-mods"

if [ ! -f "$INFO_PLIST" ] || [ ! -f "$FTL_DAT" ]; then
    echo "Target app does not look like a patchable FTL bundle: $TARGET_APP" >&2
    exit 1
fi

MOD_PATHS=()
for mod_path in "$@"; do
    if [ ! -f "$mod_path" ]; then
        echo "Missing mod file: $mod_path" >&2
        exit 1
    fi

    MOD_PATHS+=("$(cd "$(dirname "$mod_path")" && pwd)/$(basename "$mod_path")")
done

prepare_ftlman

if [ ! -f "$BACKUP_DAT" ]; then
    cp "$FTL_DAT" "$BACKUP_DAT"
fi

log "Patching extra mods into $TARGET_APP"
"$FTLMAN_BIN" patch -d "$RESOURCE_DIR" "${MOD_PATHS[@]}"

log "Re-signing app bundle..."
resign_app "$TARGET_APP"

log ""
log "Done."
log "Patched app: $TARGET_APP"
log "Backup before extra mods: $BACKUP_DAT"
