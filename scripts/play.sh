#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../"

# Utils function
indent() {
    local prefix="${1:-    }"
    shift
    "$@" 2>&1 | sed -u "s/^/$prefix/"
}

cat << 'EOF'
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

cat << 'EOF'
```
EOF
