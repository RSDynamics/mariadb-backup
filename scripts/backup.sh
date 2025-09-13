#!/bin/bash
set -euo pipefail

echo "🔁 Starting MariaDB backup..."

# Load environment variables
MYSQL_HOST=${MYSQL_HOST:-localhost}
MYSQL_PORT=${MYSQL_PORT:-3306}
MYSQL_USER=${MYSQL_USER:-BackupUsr}
MYSQL_PASSWORD=${MYSQL_PASSWORD:-}
BACKUP_DIR=${BACKUP_DIR:-/backup}
FULLBACKUPCYCLE_DAYS=${FULLBACKUPCYCLE_DAYS:-7}
KEEP_FULL=${KEEP_FULL:-3}

# Convert days to seconds
FULLBACKUPCYCLE_SECONDS=$((FULLBACKUPCYCLE_DAYS * 86400))

# Timestamp
NOW=$(date +%s)
DATE=$(date +"%Y-%m-%d_%H-%M-%S")

# Ensure backup directory exists and is writable
if ! mkdir -p "$BACKUP_DIR"; then
    echo "❌ Failed to create backup directory: $BACKUP_DIR"
    exit 1
fi
if [ ! -w "$BACKUP_DIR" ]; then
    echo "❌ Backup directory is not writable: $BACKUP_DIR"
    exit 1
fi

# Find latest full backup
LATEST_FULL=$(find "$BACKUP_DIR" -maxdepth 1 -type d -name "full_*" | sort | tail -n 1)

# Decide whether to do full or incremental
if [ -z "$LATEST_FULL" ]; then
    echo "📦 No full backup found. Creating initial full backup..."
    TARGET="$BACKUP_DIR/full_$DATE"
    TYPE="full"
else
    LAST_FULL_TIME=$(stat -c %Y "$LATEST_FULL")
    ELAPSED=$((NOW - LAST_FULL_TIME))

    if [ "$ELAPSED" -gt "$FULLBACKUPCYCLE_SECONDS" ]; then
        echo "📦 Time for new full backup (last was $((ELAPSED / 86400)) days ago)"
        TARGET="$BACKUP_DIR/full_$DATE"
        TYPE="full"
    else
        echo "➕ Creating incremental backup based on $LATEST_FULL"
        TARGET="$LATEST_FULL/inc_$DATE"
        TYPE="incremental"
    fi
fi

# Run backup
backup() {
    set -o pipefail
    if [ "$TYPE" = "full" ]; then
        echo "🔄 Running full backup to $TARGET"
        if ! mariabackup --backup \
            --host="$MYSQL_HOST" \
            --port="$MYSQL_PORT" \
            --user="$MYSQL_USER" \
            --password="$MYSQL_PASSWORD" \
            --target-dir="$TARGET"; then
            echo "❌ mariabackup full backup failed!"
            return 1
        fi
        mariabackup --prepare --target-dir="$TARGET"
    else
        echo "🔄 Running incremental backup to $TARGET"
        if ! mariabackup --backup \
            --host="$MYSQL_HOST" \
            --port="$MYSQL_PORT" \
            --user="$MYSQL_USER" \
            --password="$MYSQL_PASSWORD" \
            --target-dir="$TARGET" \
            --incremental-basedir="$LATEST_FULL"; then
            echo "❌ mariabackup incremental backup failed!"
            return 1
        fi
        mariabackup --prepare \
            --target-dir="$TARGET" \
            --incremental-basedir="$LATEST_FULL"
    fi
}

if ! backup; then
    echo "❌ Backup failed!"
    exit 1
fi

# Cleanup old backups
echo "🧹 Cleaning up old backups (keeping last $KEEP_FULL full backups)..."
find "$BACKUP_DIR" -maxdepth 1 -type d -name "full_*" | sort | head -n -"$KEEP_FULL" | while read -r old_full; do
    echo "🗑️ Removing $old_full (and all its incrementals)..."
    rm -rf "$old_full"
done

echo "✅ Backup completed: $TYPE → $TARGET"

# ⏱️ Update healthcheck timestamp
date -u > /var/log/last_backup.txt