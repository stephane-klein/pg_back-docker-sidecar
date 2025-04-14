#!/usr/bin/env bash
set -e
#
# Utils function
indent() {
    local prefix="${1:-    }"
    shift
    "$@" 2>&1 | sed -u "s/^/$prefix/"
}

cd "$(dirname "$0")/../../"

echo "docker compose down -v"
indent "    " docker compose down -v
echo ""

echo "docker compose up -d postgres1 minio --wait"
indent "    " docker compose up -d postgres1 minio --wait
echo ""

echo "./scripts/create-minio-bucket.sh"
indent "    " ./scripts/create-minio-bucket.sh
echo ""

echo "./scripts/seed.sh"
indent "    " ./scripts/seed.sh
echo ""

echo "./scripts/generate_dummy_rows_in_postgres1.sh 1000"
indent "    " ./scripts/generate_dummy_rows_in_postgres1.sh 1000
echo ""

