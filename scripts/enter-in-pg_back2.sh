#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

docker compose exec pg_back2 bash
