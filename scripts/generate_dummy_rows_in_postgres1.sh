#!/usr/bin/env bash
set -e

ROWS_COUNT=${1:-100}

cd "$(dirname "$0")/../"

docker compose exec -T postgres1 sh -c "cat << EOF | psql -U \$POSTGRES_USER \$POSTGRES_DB
select insert_dummy_records($ROWS_COUNT);
select count(*) from dummy;
\q
EOF"
