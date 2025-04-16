#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

docker compose cp ./tmp-downloads-dump/pg_globals_${@}Z.sql postgres2:/pg_globals.sql
docker compose cp ./tmp-downloads-dump/postgres_${@}Z.dump postgres2:/postgres.dump

docker compose exec -T postgres2 sh -c "cat << 'EOF' | sh
psql -U \$POSTGRES_USER \$POSTGRES_DB -f /pg_globals.sql > /dev/null 2>&1
pg_restore -c --if-exists -U \$POSTGRES_USER -d \$POSTGRES_DB /postgres.dump > /dev/null 2>&1
rm /pg_globals.sql /postgres.dump
EOF"
