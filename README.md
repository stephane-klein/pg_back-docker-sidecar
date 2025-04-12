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
[+] Running 7/7
 ✔ Container poc_pg_back_66ce9ade1421-pg_back-1    Removed                                                                      10.2s
 ✔ Container poc_pg_back_66ce9ade1421-postgres1-1  Removed                                                                       0.5s
 ✔ Container poc_pg_back_66ce9ade1421-minio-1      Removed                                                                       0.5s
 ✔ Volume poc_pg_back_66ce9ade1421_postgres1       Removed                                                                       0.1s
 ✔ Volume poc_pg_back_66ce9ade1421_postgres2       Removed                                                                       0.1s
 ✔ Volume poc_pg_back_66ce9ade1421_minio           Removed                                                                       0.1s
 ✔ Network poc_pg_back_66ce9ade1421_default        Removed                                                                       0.5s
```

I start the services:

- `postgres1`, which is the PostgreSQL instance I want to backup
- `minio` which serves as a local Object Storage
- `pg_back` a "Sidecar" Docker container that executes the [`pg_back`](https://github.com/orgrim/pg_back/) commands and runs them daily with [supercronic](https://github.com/aptible/supercronic)

```sh
$ docker compose up -d postgres1 minio pg_back --wait
[+] Running 6/6
 ✔ Network poc_pg_back_66ce9ade1421_default        Created                                                                       0.4s
 ✔ Volume "poc_pg_back_66ce9ade1421_minio"         Created                                                                       0.0s
 ✔ Volume "poc_pg_back_66ce9ade1421_postgres1"     Created                                                                       0.0s
 ✔ Container poc_pg_back_66ce9ade1421-minio-1      Healthy                                                                       6.6s
 ✔ Container poc_pg_back_66ce9ade1421-postgres1-1  Healthy                                                                       6.6s
 ✔ Container poc_pg_back_66ce9ade1421-pg_back-1    Healthy                                                                       6.5s
```

I prepare a Bucket in Minio named `pg-back`:

```sh
$./scripts/create-minio-bucket.sh
Added `myminio` successfully.
Bucket created successfully `myminio/pg-back`.
```

I create a data model and inject dummy data in the `postgres1` instance:

```sh
$ ./scripts/seed.sh
NOTICE:  table "dummy" does not exist, skipping
NOTICE:  function public.insert_dummy_records() does not exist, skipping
$ ./scripts/generate_dummy_rows_in_postgres1.sh 1000
```

Now, I will execute a dump with `pg_back`:

```sh
$ ./scripts/execute-pg_back-dump.sh
2025/04/12 08:56:40 INFO: dumping globals
2025/04/12 08:56:40 INFO: dumping instance configuration
2025/04/12 08:56:40 INFO: uploading /var/backups/postgresql/pg_globals_2025-04-12T08:56:40Z.sql to S3 bucket pg-back
2025/04/12 08:56:40 INFO: uploading /var/backups/postgresql/pg_settings_2025-04-12T08:56:40Z.out to S3 bucket pg-back
2025/04/12 08:56:40 INFO: uploading /var/backups/postgresql/hba_file_2025-04-12T08:56:40Z.out to S3 bucket pg-back
2025/04/12 08:56:40 INFO: dumping database postgres
2025/04/12 08:56:40 INFO: uploading /var/backups/postgresql/ident_file_2025-04-12T08:56:40Z.out to S3 bucket pg-back
2025/04/12 08:56:40 INFO: dump of postgres to /var/backups/postgresql/postgres_2025-04-12T08:56:40Z.dump done
2025/04/12 08:56:40 INFO: uploading /var/backups/postgresql/postgres_2025-04-12T08:56:40Z.dump to S3 bucket pg-back
2025/04/12 08:56:40 INFO: waiting for postprocessing to complete
2025/04/12 08:56:40 INFO: purging old dumps
```

I wait a few seconds before injecting more data into `postgres1` and performing a new dump:

```sh
$ ./scripts/generate_dummy_rows_in_postgres1.sh 1000
$ ./scripts/execute-pg_back-dump.sh
2025/04/12 08:57:01 INFO: dumping globals
2025/04/12 08:57:01 INFO: dumping instance configuration
2025/04/12 08:57:01 INFO: uploading /var/backups/postgresql/pg_globals_2025-04-12T08:57:01Z.sql to S3 bucket pg-back
2025/04/12 08:57:01 INFO: uploading /var/backups/postgresql/pg_settings_2025-04-12T08:57:01Z.out to S3 bucket pg-back
2025/04/12 08:57:01 INFO: uploading /var/backups/postgresql/hba_file_2025-04-12T08:57:01Z.out to S3 bucket pg-back
2025/04/12 08:57:01 INFO: dumping database postgres
2025/04/12 08:57:01 INFO: uploading /var/backups/postgresql/ident_file_2025-04-12T08:57:01Z.out to S3 bucket pg-back
2025/04/12 08:57:01 INFO: dump of postgres to /var/backups/postgresql/postgres_2025-04-12T08:57:01Z.dump done
2025/04/12 08:57:01 INFO: uploading /var/backups/postgresql/postgres_2025-04-12T08:57:01Z.dump to S3 bucket pg-back
2025/04/12 08:57:01 INFO: waiting for postprocessing to complete
2025/04/12 08:57:01 INFO: purging old dumps
```

Here is the list of files uploaded to Minio Object Storage:

```sh
$ ./scripts/execute-pg_back-list-remote.sh
hba_file_2025-04-12T08:56:40Z.out
hba_file_2025-04-12T08:57:01Z.out
ident_file_2025-04-12T08:56:40Z.out
ident_file_2025-04-12T08:57:01Z.out
pg_globals_2025-04-12T08:56:40Z.sql
pg_globals_2025-04-12T08:57:01Z.sql
pg_settings_2025-04-12T08:56:40Z.out
pg_settings_2025-04-12T08:57:01Z.out
postgres_2025-04-12T08:56:40Z.dump
postgres_2025-04-12T08:57:01Z.dump
```

I observe something I don't like. Each backup consists of 5 files. These files are not grouped in a folder.
I find this makes reading the list of backups difficult.

Another thing I don't like is that I notice that the archives are still present in the container,
even after being uploaded to Object Storage:

```sh
$ docker compose exec pg_back ls /var/backups/postgresql/ -1
hba_file_2025-04-12T08:56:40Z.out
hba_file_2025-04-12T08:57:01Z.out
ident_file_2025-04-12T08:56:40Z.out
ident_file_2025-04-12T08:57:01Z.out
pg_globals_2025-04-12T08:56:40Z.sql
pg_globals_2025-04-12T08:57:01Z.sql
pg_settings_2025-04-12T08:56:40Z.out
pg_settings_2025-04-12T08:57:01Z.out
postgres_2025-04-12T08:56:40Z.dump
postgres_2025-04-12T08:57:01Z.dump
```
