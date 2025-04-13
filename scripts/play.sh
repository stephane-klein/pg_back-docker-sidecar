#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

# Utils function
indent() {
    local prefix="${1:-    }"
    shift
    "$@" 2>&1 | sed -u "s/^/$prefix/"
}

git clean -Xf tmp-downloads-dump/ > /dev/null

cat << 'EOF'
# POC pg_back

In this repository I want to test the implementation of [pg_back](https://github.com/orgrim/pg_back/) deployed in a Docker container as a "sidecar" to backup a PostgreSQL database deployed via Docker.

For more context, see the following note written in French: https://notes.sklein.xyz/Projet%2027/

## Prerequisites

- [mise](https://mise.jdx.dev/)
- [Docker Engine](https://docs.docker.com/engine/) (tested with `24.0.6`)

## Services versions

- PostgreSQL 17
- [pg_back 2.5.0](https://github.com/orgrim/pg_back/releases/tag/v2.5.0)

## Environment preparation

If you don't use [Mise](https://mise.jdx.dev/) or [direnv](https://direnv.net/), you need to execute the following command before running `docker compose`:

```
$ source .envrc
```

```sh
$ mise install
$ docker compose build
```

## Start or restart the playground test scenario

I start by resetting the environment:

```sh
$ docker compose down -v
EOF
docker compose down -v

cat << 'EOF'
```

I start the services:

- `postgres1`, which is the PostgreSQL instance I want to backup
- `minio` which serves as a local Object Storage
- `pg_back` a "Sidecar" Docker container that executes the [`pg_back`](https://github.com/orgrim/pg_back/) commands and runs them daily with [supercronic](https://github.com/aptible/supercronic)

```sh
$ docker compose up -d postgres1 minio pg_back --wait
EOF

docker compose up -d postgres1 minio pg_back --wait

cat << 'EOF'
```

I prepare a Bucket in Minio named `pg-back`:

```sh
$./scripts/create-minio-bucket.sh
EOF

./scripts/create-minio-bucket.sh

cat << 'EOF'
```

I create a data model and inject dummy data in the `postgres1` instance:

```sh
$ ./scripts/seed.sh
EOF
./scripts/seed.sh
cat << 'EOF'
$ ./scripts/generate_dummy_rows_in_postgres1.sh 1000
EOF

./scripts/generate_dummy_rows_in_postgres1.sh

cat << 'EOF'
```

Now, I will execute a dump with `pg_back`:

```sh
$ ./scripts/execute-pg_back-dump.sh
EOF

./scripts/execute-pg_back-dump.sh


cat << 'EOF'
```

I wait a few seconds (30s) before injecting more data into `postgres1` and performing a new dump:

```sh
$ ./scripts/generate_dummy_rows_in_postgres1.sh 1000
$ ./scripts/execute-pg_back-dump.sh
EOF

sleep 30s

./scripts/generate_dummy_rows_in_postgres1.sh 1000
./scripts/execute-pg_back-dump.sh

cat << 'EOF'
```

Here is the list of files uploaded to Minio Object Storage:

```sh
$ ./scripts/execute-pg_back-list-remote.sh
EOF

./scripts/execute-pg_back-list-remote.sh

cat << 'EOF'
```

I observe something I don't like. Each backup consists of 5 files. These files are not grouped in a folder.
I find this makes reading the list of backups difficult.

I also observe that the `ENCRYPT: "true"` parameter has been taken into account, the archive files appear to be encrypted with Age.

Another thing I don't like is that I notice that the archives are still present in the container,
even after being uploaded to Object Storage:

```sh
$ docker compose exec pg_back ls /var/backups/postgresql/ -1
EOF

docker compose exec pg_back ls /var/backups/postgresql/ -1

cat << 'EOF'
```

I now wait 45s before injecting data and performing a new dump.
This 45s waiting period allows me to observe if the `PURGE_OLDER_THAN: "60s"` parameter is
correctly taken into account by `pg_back`.

```sh
$ ./scripts/generate_dummy_rows_in_postgres1.sh 1000
$ ./scripts/execute-pg_back-dump.sh
EOF

sleep 45s

./scripts/generate_dummy_rows_in_postgres1.sh 1000
./scripts/execute-pg_back-dump.sh

cat << 'EOF'
```

I check that the first archive has been deleted:

```sh
$ ./scripts/execute-pg_back-list-remote.sh
EOF

./scripts/execute-pg_back-list-remote.sh

LAST_ARCHIVE_DATETIME=$(./scripts/execute-pg_back-list-remote.sh | tail --lines=1 | sed -E 's/.*postgres_([0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2})Z.*/\1/')

cat << 'EOF'
```

This is how to download the latest archive locally:

```sh
EOF

cat << EOF
./scripts/download-dump.sh ${LAST_ARCHIVE_DATETIME}
EOF

./scripts/download-dump.sh ${LAST_ARCHIVE_DATETIME}

cat << 'EOF'
```

Les archives ont été download dans `./tmp-downloads-dump/`:

```sh
$ ls -lha ./tmp-downloads-dump/
EOF

ls -lha ./tmp-downloads-dump/

cat << 'EOF'
```

Decrypting `*.age` archives with Age:

```sh
$ ./scripts/age-decrypt-downloads-dump.sh
```

I start the `postgres2` instance where I want to restore the backups:

```sh
$ docker compose up -d postgres2 --wait
EOF

./scripts/age-decrypt-downloads-dump.sh

docker compose up -d postgres2 --wait

cat << 'EOF'
```
EOF

cat << EOF
Import \`${LAST_ARCHIVE_DATETIME}\` local archive to \`postgres2\`:
EOF

cat << 'EOF'
```sh
EOF

cat << EOF
$ ./scripts/postgres2-import-local-dump.sh ${LAST_ARCHIVE_DATETIME}
EOF

./scripts/postgres2-import-local-dump.sh ${LAST_ARCHIVE_DATETIME}

cat << 'EOF'
```

Now I check that the `dummy` table and its data have been correctly restored in the `postgres2` instance:

```sh
$ echo "select count(*) from dummy;" | ./scripts/postgres2-sql.sh
EOF

echo "select count(*) from dummy;" | ./scripts/postgres2-sql.sh

cat << 'EOF'
```
EOF
