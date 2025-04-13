#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

docker compose exec -T pg_back2 sh -c "cat << 'EOF' | sh
pg_back --download s3 foobar/*${@}* --decrypt \"*\"
psql -U \$POSTGRES_USER -p \$POSTGRES_PORT -h \$POSTGRES_HOST \$POSTGRES_DB -f /var/backups/postgresql/foobar/pg_globals_${@}Z.sql > /dev/null 2>&1
pg_restore -c -U \$POSTGRES_USER -p \$POSTGRES_PORT -h \$POSTGRES_HOST -d \$POSTGRES_DBNAME /var/backups/postgresql/foobar/postgres_${@}Z.dump > /dev/null 2>&1
rm -rf /var/backups/postgresql/
EOF"
