FROM alpine:latest

# Install dependencies
RUN apk add --no-cache mariadb mariadb-client mariadb-backup bash tzdata curl

# Copy scripts
COPY ./scripts/ /scripts/
RUN chmod +x /scripts/*.sh

# Create non-root user
RUN addgroup -S appuser && adduser -S appuser -G appuser

# Create default backup and log dir
RUN mkdir -p /var/log && chown appuser:appuser /var/log
RUN mkdir -p /backup && chown appuser:appuser /backup
RUN mkdir -p /scripts/crontabs && chown appuser:appuser /scripts/crontabs

# Switch to non-root user
USER appuser

# Docker healthcheck
HEALTHCHECK --interval=30m --timeout=10s --start-period=5m --retries=3 \
  CMD /scripts/healthcheck.sh

# Entrypoint
ENTRYPOINT ["/scripts/entrypoint.sh"]
