#!/bin/sh

# Fail if no backup has run in the last 36 hours
if [ ! -f /var/log/last_backup.txt ]; then
  echo "❌ No backup record found"
  exit 1
fi

# Gebruik bestandstijd als timestamp
LAST_TS=$(date -u -r /var/log/last_backup.txt +%s)
NOW_TS=$(date -u +%s)
DIFF=$((NOW_TS - LAST_TS))

# 36 uur = 129600 seconden
if [ "$DIFF" -gt 129600 ]; then
  echo "❌ Last backup too old: $DIFF seconds ago"
  exit 1
fi

echo "✅ Backup is recent"
exit 0
