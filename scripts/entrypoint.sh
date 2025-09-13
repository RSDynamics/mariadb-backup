#!/bin/bash
set -e

# Default to backup mode if MODE is not set
MODE=${MODE:-backup}

echo "🚀 Container starting in $MODE mode..."

if [ "$MODE" = "restore" ]; then
    if [ -z "$RESTORE_SOURCE" ]; then
        echo "❌ RESTORE_SOURCE not specified."
        exit 1
    fi
    /scripts/restore.sh "$RESTORE_SOURCE"
    echo "🛑 Restore completed. Container will now exit."
    exit 0

elif [ "$MODE" = "manual" ]; then
    echo "🧪 Manual backup triggered..."
    /scripts/backup.sh
    echo "✅ Manual backup completed. Container will now exit."
    exit 0

else
    echo "⏰ Scheduling backup via cron: $BACKUP_SCHEDULE"
    echo "$CRON_SCHEDULE /scripts/backup.sh" > /scripts/crontabs/appuser
    crond -c /scripts/crontabs -f -l 8
fi
