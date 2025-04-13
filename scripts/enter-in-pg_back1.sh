#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

docker compose exec pg_back1 bash
