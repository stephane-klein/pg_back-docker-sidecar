#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"


# Generate pg_back_postgres1.conf file

POSTGRES1_DOCKER_ID=$(cd ..; docker compose ps postgres1 --format json | jq .ID -r)

export POSTGRES_HOST="localhost"
if [ -z "$POSTGRES1_DOCKER_ID" ]; then
    echo "Warning: No PostgreSQL Docker container is currently running"
else
    export POSTGRES_PORT=$(cd .. ; docker inspect ${POSTGRES1_DOCKER_ID} | jq -r '.[].NetworkSettings.Ports["5432/tcp"][0].HostPort')
fi
export POSTGRES_USER="postgres"
export POSTGRES_DBNAME="postgres"
export POSTGRES_PASSWORD="password"

export BACKUP_DIRECTORY="$(pwd)/tmp-pg_back/postgres1/"

export UPLOAD="s3"
export UPLOAD_PREFIX="foobar"

export S3_KEY_ID=admin
export S3_SECRET=password
export S3_ENDPOINT="http://localhost:9000/"
export S3_REGION="us-east-1"
export S3_BUCKET="pg-back"
export S3_FORCE_PATH="true"
export S3_TLS="false"

export PURGE_OLDER_THAN="60s"
export PURGE_REMOTE="true"

export ENCRYPT="true"
export AGE_CIPHER_PUBLIC_KEY="age12q38nk94gwgkqu9c9f7l2dyg2fnv4u9qmnq0eahcrwu0vudenyvs52gnt9"
export AGE_CIPHER_PRIVATE_KEY="AGE-SECRET-KEY-13MRMM74CQ2JA000HGZ86Y4SVLYS468W0YR4KPXHG7KSX5K5YSLESRCD37L"

gomplate --file ../pg_back.conf.tmpl --out ./pg_back_postgres1.conf

# Generate pg_back_postgres2.conf file

POSTGRES2_DOCKER_ID=$(cd ..; docker compose ps postgres2 --format json | jq .ID -r)

export POSTGRES_HOST="localhost"
if [ -z "$POSTGRES2_DOCKER_ID" ]; then
    echo "Warning: No PostgreSQL Docker container is currently running"
else
    export POSTGRES_PORT=$(cd .. ; docker inspect ${POSTGRES2_DOCKER_ID} | jq -r '.[].NetworkSettings.Ports["5432/tcp"][0].HostPort')
fi
export POSTGRES_USER="postgres"
export POSTGRES_DBNAME="postgres"
export POSTGRES_PASSWORD="password"

export BACKUP_DIRECTORY="$(pwd)/tmp-pg_back/postgres2/"

export UPLOAD="s3"
export UPLOAD_PREFIX="foobar"

export S3_KEY_ID=admin
export S3_SECRET=password
export S3_ENDPOINT="http://localhost:9000/"
export S3_REGION="us-east-1"
export S3_BUCKET="pg-back"
export S3_FORCE_PATH="true"
export S3_TLS="false"

export PURGE_OLDER_THAN="60s"
export PURGE_REMOTE="true"

export ENCRYPT="true"
export AGE_CIPHER_PUBLIC_KEY="age12q38nk94gwgkqu9c9f7l2dyg2fnv4u9qmnq0eahcrwu0vudenyvs52gnt9"
export AGE_CIPHER_PRIVATE_KEY="AGE-SECRET-KEY-13MRMM74CQ2JA000HGZ86Y4SVLYS468W0YR4KPXHG7KSX5K5YSLESRCD37L"

gomplate --file ../pg_back.conf.tmpl --out ./pg_back_postgres2.conf
