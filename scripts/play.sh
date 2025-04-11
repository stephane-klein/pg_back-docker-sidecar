#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

# Utils function
indent() {
    local prefix="${1:-    }"
    shift
    "$@" 2>&1 | sed -u "s/^/$prefix/"
}

echo "docker compose down -v"
indent "    " docker compose down -v
echo ""

echo "docker compose up -d postgres1 minio pg_back --wait"
indent "    " docker compose up -d postgres1 pg_back --wait
echo ""

echo "./scripts/create-minio-bucket.sh"
./scripts/create-minio-bucket.sh > /dev/null

echo "./scripts/seed.sh"
./scripts/seed.sh > /dev/null
echo "./scripts/generate_dummy_rows_in_postgres1.sh 1000"
./scripts/generate_dummy_rows_in_postgres1.sh 1000 > /dev/null
