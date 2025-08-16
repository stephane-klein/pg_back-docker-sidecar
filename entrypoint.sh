#!/bin/bash
set -euo pipefail

gomplate --file /pg_back.conf.tmpl --out /etc/pg_back/pg_back.conf

echo "${POSTGRES_HOST}:${POSTGRES_PORT}:*:${POSTGRES_USER}:${POSTGRES_PASSWORD}" > ~/.pgpass
chmod 0600 ~/.pgpass

# Set up environment variables to let aws cli access to the object
# storage environment that has the backups made by pg_back
export AWS_ACCESS_KEY_ID="${S3_KEY_ID}"
export AWS_SECRET_ACCESS_KEY="${S3_SECRET}"
export AWS_ENDPOINT_URL="${S3_ENDPOINT}"
export AWS_DEFAULT_REGION="${S3_REGION}"

if [[ $# -ne 0 ]]; then
    exec "$@"
    exit 0
fi

echo "$BACKUP_CRON /usr/local/bin/pg_back" > /main.crontab


if [[ "${DISABLE_CRON,,}" == "true" ]] || [[ "${DISABLE_CRON,,}" == "yes" ]] || [[ "${DISABLE_CRON,,}" == "1" ]]; then
    tail -f /dev/null
else
    supercronic /main.crontab
fi
