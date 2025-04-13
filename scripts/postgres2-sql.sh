#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

docker compose exec -iT postgres2 sh -c "psql --quiet -U \$POSTGRES_USER \$POSTGRES_DB"
