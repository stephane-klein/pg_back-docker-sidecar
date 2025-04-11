#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

docker compose exec -T minio sh -c "cat << 'EOF' | sh
mc alias set myminio http://localhost:9000 \${MINIO_ACCESS_KEY} \${MINIO_SECRET_KEY}
mc mb myminio/pg-back --ignore-existing;
EOF"
