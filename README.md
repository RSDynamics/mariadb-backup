# 🐬 MariaDB Backup & Restore Container

A lightweight Alpine-based container for automated MariaDB backups and restores. Supports full & incremental backups, healthchecks, and manual restore operations.

---

## 🚀 Features

- 🔁 Daily full/incremental backups via cron  
- 🔄 Restore from backups (auto-detects full/incremental)  
- 🧪 Healthcheck: verifies recent backup activity  
- 🐳 Docker-ready with `MODE=backup`, `restore`, or `manual`  
- 📦 Volumes for backup data and database files  
- 🧼 Cleanup of old backups based on retention settings  

---

## ⚙️ Usage

### 1. Clone & build

```bash
git clone https://github.com/yourrepo/mariadb-backup
cd mariadb-backup
docker-compose up --build -d
```

### 2. Modes

| MODE      | Description                             |
|-----------|-----------------------------------------|
| `backup`  | Starts cronjob and performs backups     |
| `restore` | Restores a backup and then exits        |
| `manual`  | Runs a single backup and then exits     |

Set `MODE` via `.env`, environment variables, or in your Portainer stack.

---

## 🧪 Healthcheck

The container includes a healthcheck that verifies whether the last backup was performed within the past 36 hours. It checks the **modification time** of `/var/log/last_backup.txt`.

Check status via:

```bash
docker inspect --format='{{json .State.Health}}' mariadb-backup
```

Or view it in Portainer under “Health”.

---

## 📁 Volumes

| Container Path         | Description                         |
|------------------------|-------------------------------------|
| `/backup`              | Location of backup files            |
| `/var/log`             | Stores healthcheck timestamp        |
| `/var/lib/mysql`       | MariaDB datadir (used for restore)  |

Ensure these paths are mounted and writable by the container.

---

## 🔧 Environment Variables

| Variable                 | Default           | Description                                  |
|--------------------------|-------------------|----------------------------------------------|
| `MODE`                   | `backup`          | `backup`, `restore`, or `manual`             |
| `CRON_SCHEDULE`          | `0 3 * * *`       | Cron expression for scheduled backups        |
| `MYSQL_HOST`             | `localhost`       | MariaDB host                                 |
| `MYSQL_PORT`             | `3306`            | MariaDB port                                 |
| `MYSQL_USER`             | `BackupUsr`       | User with backup privileges                  |
| `MYSQL_PASSWORD`         | *(required)*      | Password for the user                        |
| `BACKUP_DIR`             | `/backup`         | Path to backup directory                     |
| `RESTORE_SOURCE`         | *(required)*      | Path to the backup you want to restore       |
| `RESTORE_TARGET_DIR`     | `/var/lib/mysql`  | Target directory for restore                 |
| `FULLBACKUPCYCLE_DAYS`   | `7`               | Days between full backups                    |
| `KEEP_FULL`              | `3`               | Number of full backups to retain             |
| `TZ`                     | `Europe/Amsterdam`| Timezone setting                             |

---

## 📦 Manual Backup

Run a one-time backup manually:

```bash
docker exec -it mariadb-backup /scripts/backup.sh
```

Or set `MODE=manual` in your stack to run once and exit.

---

## 📄 Restore

Set `MODE=restore` and specify `RESTORE_SOURCE`:

```yaml
environment:
  - MODE=restore
  - RESTORE_SOURCE=/backup/full_2025-09-13_03-00-00/inc_2025-09-15_03-00-00
```

The container will detect whether it's a full or incremental backup and restore accordingly.

---

## 🧼 Cleanup

The backup script automatically removes old backups based on:

- `FULLBACKUPCYCLE_DAYS`: how often a new full backup is created  
- `KEEP_FULL`: how many full backups to retain (older ones are deleted)

Incrementals associated with old full backups are also removed.

---

## 🛡️ Security & Permissions

- Container runs as non-root `appuser`  
- `/backup` and `/var/log` are owned by `appuser`  
- Cron runs in foreground (`crond -f`) to keep container alive and expose logs  
- Healthcheck and manual scripts are executed directly without needing root

---

## 📋 License

MIT — use it, modify it, and share it freely.
