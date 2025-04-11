#!/bin/bash
set -euo pipefail

gomplate --file /pg_back.conf.tmpl --out /etc/pg_back/pg_back.conf

echo "${POSTGRES_HOST}:${POSTGRES_PORT}:*:${POSTGRES_USER}:${POSTGRES_PASSWORD}" > ~/.pgpass
chmod 0600 ~/.pgpass

if [[ $# -ne 0 ]]; then
    exec "$@"
    exit 0
fi

echo "$BACKUP_CRON /usr/local/bin/pg_back" > /main.crontab

supercronic /main.crontab
