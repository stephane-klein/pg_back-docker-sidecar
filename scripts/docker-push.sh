#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

docker push stephaneklein/pg_back-docker-sidecar:2.5.0-delete-local-file-after-upload
