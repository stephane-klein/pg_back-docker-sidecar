#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

docker push stephaneklein/pg_back-docker-sidecar:latest
