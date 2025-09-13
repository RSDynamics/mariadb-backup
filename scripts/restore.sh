#!/bin/bash
set -eu

if [ "$(id -u)" -ne 0 ]; then
    echo "❌ This script must be run as root (for mariabackup --copy-back)."
    exit 1
fi

echo "🔄 Starting MariaDB restore..."

BACKUP_DIR=${BACKUP_DIR:-/backup}
RESTORE_TARGET_DIR=${RESTORE_TARGET_DIR:-/var/lib/mysql}
RESTORE_SOURCE="${RESTORE_SOURCE:-$1:-}"
DRY_RUN=${DRY_RUN:-false}

if [ -z "$RESTORE_SOURCE" ]; then
    echo "❌ No backup directory specified via RESTORE_SOURCE or CLI argument."
    echo "Usage: ./restore.sh /backup/full_YYYY-MM-DD_HH-MM-SS[/inc_YYYY-MM-DD_HH-MM-SS]"
    echo "Example: ./restore.sh /backup/full_2024-09-01_00-00-00/inc_2024-09-03_00-00-00"
    exit 1
fi

if [ ! -d "$RESTORE_SOURCE" ]; then
    echo "❌ Backup directory not found: $RESTORE_SOURCE"
    exit 1
fi

BASENAME=$(basename "$RESTORE_SOURCE")
PARENTDIR=$(basename "$(dirname "$RESTORE_SOURCE")")

run_cmd() {
    if [ "$DRY_RUN" = "true" ]; then
        echo "[DRY RUN] $*"
    else
        "$@"
    fi
}

if [[ "$BASENAME" == full_* ]]; then
    echo "📦 Detected full backup. Preparing and restoring..."
    run_cmd "mariabackup --prepare --target-dir=\"$RESTORE_SOURCE\""
    INCREMENTALS=$(find "$RESTORE_SOURCE" -maxdepth 1 -type d -name "inc_*" | sort -V)
    for INC in $INCREMENTALS; do
        echo "➕ Applying incremental: $INC"
        run_cmd "mariabackup --prepare --target-dir=\"$RESTORE_SOURCE\" --incremental-dir=\"$INC\""
    done
    run_cmd "mariabackup --copy-back --target-dir=\"$RESTORE_SOURCE\""

elif [[ "$BASENAME" == inc_* && "$PARENTDIR" == full_* ]]; then
    echo "📦 Detected incremental backup. Preparing up to this incremental..."
    FULL_DIR=$(dirname "$RESTORE_SOURCE")
    run_cmd "mariabackup --prepare --target-dir=\"$FULL_DIR\""
    INCREMENTALS=$(find "$FULL_DIR" -maxdepth 1 -type d -name "inc_*" | sort -V)
    for INC in $INCREMENTALS; do
        echo "➕ Applying incremental: $INC"
        run_cmd "mariabackup --prepare --target-dir=\"$FULL_DIR\" --incremental-dir=\"$INC\""
        if [[ "$INC" == "$RESTORE_SOURCE" ]]; then
            break
        fi
    done
    run_cmd "mariabackup --copy-back --target-dir=\"$FULL_DIR\""

else
    echo "❌ Please specify a full backup directory or an incremental inside a full backup directory."
    exit 1
fi

if [ -d "$RESTORE_TARGET_DIR" ]; then
    run_cmd "chown -R mysql:mysql \"$RESTORE_TARGET_DIR\""
fi

echo "✅ Restore completed."