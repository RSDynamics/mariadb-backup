# Config
COMPOSE=docker-compose
SERVICE=mariadb-backup

# Build container
build:
    $(COMPOSE) build

# Start containers
up:
    $(COMPOSE) up -d

# Stop containers
down:
    $(COMPOSE) down

# Run manual backup
backup:
    docker exec -it $(SERVICE) /scripts/backup.sh

# Run manual restore
restore:
    docker exec -it $(SERVICE) /scripts/restore.sh

# View logs
logs:
    docker logs -f $(SERVICE)

# Show health status
health:
    docker inspect --format='{{json .State.Health}}' $(SERVICE)

# Rebuild and restart
rebuild:
    $(COMPOSE) down
    $(COMPOSE) build
    $(COMPOSE) up -d
