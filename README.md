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
 ✔ Container poc_pg_back_66ce9ade1421-pg_back-1    Removed                                                                      10.3s
 ✔ Container poc_pg_back_66ce9ade1421-postgres1-1  Removed                                                                       0.3s
 ✔ Container poc_pg_back_66ce9ade1421-minio-1      Removed                                                                       0.4s
 ✔ Volume poc_pg_back_66ce9ade1421_postgres1       Removed                                                                       0.0s
 ✔ Volume poc_pg_back_66ce9ade1421_postgres2       Removed                                                                       0.0s
 ✔ Volume poc_pg_back_66ce9ade1421_minio           Removed                                                                       0.0s
 ✔ Network poc_pg_back_66ce9ade1421_default        Removed                                                                       0.3s
```

I start the services:

- `postgres1`, which is the PostgreSQL instance I want to backup
- `minio` which serves as a local Object Storage
- `pg_back` a "Sidecar" Docker container that executes the [`pg_back`](https://github.com/orgrim/pg_back/) commands and runs them daily with [supercronic](https://github.com/aptible/supercronic)

```sh
$ docker compose up -d postgres1 minio pg_back --wait
[+] Running 6/6
 ✔ Network poc_pg_back_66ce9ade1421_default        Created                                                                       0.2s
 ✔ Volume "poc_pg_back_66ce9ade1421_postgres1"     Created                                                                       0.0s
 ✔ Volume "poc_pg_back_66ce9ade1421_minio"         Created                                                                       0.0s
 ✔ Container poc_pg_back_66ce9ade1421-postgres1-1  Healthy                                                                       6.6s
 ✔ Container poc_pg_back_66ce9ade1421-minio-1      Healthy                                                                       6.6s
 ✔ Container poc_pg_back_66ce9ade1421-pg_back-1    Healthy                                                                       6.4s
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
 2025/04/12 09:25:17 INFO: dumping globals
2025/04/12 09:25:17 INFO: dumping instance configuration
2025/04/12 09:25:17 INFO: uploading /var/backups/postgresql/pg_globals_2025-04-12T09:25:17Z.sql to S3 bucket pg-back
2025/04/12 09:25:17 INFO: uploading /var/backups/postgresql/pg_settings_2025-04-12T09:25:17Z.out to S3 bucket pg-back
2025/04/12 09:25:17 INFO: uploading /var/backups/postgresql/hba_file_2025-04-12T09:25:17Z.out to S3 bucket pg-back
2025/04/12 09:25:17 INFO: dumping database postgres
2025/04/12 09:25:17 INFO: uploading /var/backups/postgresql/ident_file_2025-04-12T09:25:17Z.out to S3 bucket pg-back
2025/04/12 09:25:17 INFO: dump of postgres to /var/backups/postgresql/postgres_2025-04-12T09:25:17Z.dump done
2025/04/12 09:25:17 INFO: uploading /var/backups/postgresql/postgres_2025-04-12T09:25:17Z.dump to S3 bucket pg-back
2025/04/12 09:25:17 INFO: waiting for postprocessing to complete
2025/04/12 09:25:17 INFO: purging old dumps
```

I wait a few seconds (30s) before injecting more data into `postgres1` and performing a new dump:

```sh
$ ./scripts/generate_dummy_rows_in_postgres1.sh 1000
$ ./scripts/execute-pg_back-dump.sh
2025/04/12 09:25:48 INFO: dumping globals
2025/04/12 09:25:48 INFO: dumping instance configuration
2025/04/12 09:25:48 INFO: uploading /var/backups/postgresql/pg_globals_2025-04-12T09:25:48Z.sql to S3 bucket pg-back
2025/04/12 09:25:48 INFO: uploading /var/backups/postgresql/pg_settings_2025-04-12T09:25:48Z.out to S3 bucket pg-back
2025/04/12 09:25:48 INFO: uploading /var/backups/postgresql/hba_file_2025-04-12T09:25:48Z.out to S3 bucket pg-back
2025/04/12 09:25:48 INFO: dumping database postgres
2025/04/12 09:25:48 INFO: uploading /var/backups/postgresql/ident_file_2025-04-12T09:25:48Z.out to S3 bucket pg-back
2025/04/12 09:25:48 INFO: dump of postgres to /var/backups/postgresql/postgres_2025-04-12T09:25:48Z.dump done
2025/04/12 09:25:48 INFO: uploading /var/backups/postgresql/postgres_2025-04-12T09:25:48Z.dump to S3 bucket pg-back
2025/04/12 09:25:48 INFO: waiting for postprocessing to complete
2025/04/12 09:25:48 INFO: purging old dumps
```

Here is the list of files uploaded to Minio Object Storage:

```sh
$ ./scripts/execute-pg_back-list-remote.sh
hba_file_2025-04-12T09:25:17Z.out
hba_file_2025-04-12T09:25:48Z.out
ident_file_2025-04-12T09:25:17Z.out
ident_file_2025-04-12T09:25:48Z.out
pg_globals_2025-04-12T09:25:17Z.sql
pg_globals_2025-04-12T09:25:48Z.sql
pg_settings_2025-04-12T09:25:17Z.out
pg_settings_2025-04-12T09:25:48Z.out
postgres_2025-04-12T09:25:17Z.dump
postgres_2025-04-12T09:25:48Z.dump
```

I observe something I don't like. Each backup consists of 5 files. These files are not grouped in a folder.
I find this makes reading the list of backups difficult.

Another thing I don't like is that I notice that the archives are still present in the container,
even after being uploaded to Object Storage:

```sh
$ docker compose exec pg_back ls /var/backups/postgresql/ -1
hba_file_2025-04-12T09:25:17Z.out
hba_file_2025-04-12T09:25:48Z.out
ident_file_2025-04-12T09:25:17Z.out
ident_file_2025-04-12T09:25:48Z.out
pg_globals_2025-04-12T09:25:17Z.sql
pg_globals_2025-04-12T09:25:48Z.sql
pg_settings_2025-04-12T09:25:17Z.out
pg_settings_2025-04-12T09:25:48Z.out
postgres_2025-04-12T09:25:17Z.dump
postgres_2025-04-12T09:25:48Z.dump
```

I now wait 45s before injecting data and performing a new dump.
This 45s waiting period allows me to observe if the `PURGE_OLDER_THAN: "60s"` parameter is
correctly taken into account by `pg_back`.

```sh
$ ./scripts/generate_dummy_rows_in_postgres1.sh 1000
$ ./scripts/execute-pg_back-dump.sh
2025/04/12 09:26:34 INFO: dumping globals
2025/04/12 09:26:34 INFO: dumping instance configuration
2025/04/12 09:26:34 INFO: uploading /var/backups/postgresql/pg_globals_2025-04-12T09:26:34Z.sql to S3 bucket pg-back
2025/04/12 09:26:34 INFO: uploading /var/backups/postgresql/pg_settings_2025-04-12T09:26:34Z.out to S3 bucket pg-back
2025/04/12 09:26:34 INFO: uploading /var/backups/postgresql/hba_file_2025-04-12T09:26:34Z.out to S3 bucket pg-back
2025/04/12 09:26:34 INFO: dumping database postgres
2025/04/12 09:26:34 INFO: uploading /var/backups/postgresql/ident_file_2025-04-12T09:26:34Z.out to S3 bucket pg-back
2025/04/12 09:26:34 INFO: dump of postgres to /var/backups/postgresql/postgres_2025-04-12T09:26:34Z.dump done
2025/04/12 09:26:34 INFO: uploading /var/backups/postgresql/postgres_2025-04-12T09:26:34Z.dump to S3 bucket pg-back
2025/04/12 09:26:34 INFO: waiting for postprocessing to complete
2025/04/12 09:26:34 INFO: purging old dumps
2025/04/12 09:26:34 INFO: removing /var/backups/postgresql/postgres_2025-04-12T09:25:17Z.dump
2025/04/12 09:26:34 INFO: removing /var/backups/postgresql/pg_globals_2025-04-12T09:25:17Z.sql
2025/04/12 09:26:34 INFO: removing /var/backups/postgresql/pg_settings_2025-04-12T09:25:17Z.out
2025/04/12 09:26:34 INFO: removing /var/backups/postgresql/hba_file_2025-04-12T09:25:17Z.out
2025/04/12 09:26:34 INFO: removing /var/backups/postgresql/ident_file_2025-04-12T09:25:17Z.out
```

In the output above, I notice that `pg_back` has deleted the old local archive but the archive uploaded to S3 has not been deleted, I think this is a bug:

```sh
$ ./scripts/execute-pg_back-list-remote.sh
hba_file_2025-04-12T09:25:17Z.out
hba_file_2025-04-12T09:25:48Z.out
hba_file_2025-04-12T09:26:34Z.out
ident_file_2025-04-12T09:25:17Z.out
ident_file_2025-04-12T09:25:48Z.out
ident_file_2025-04-12T09:26:34Z.out
pg_globals_2025-04-12T09:25:17Z.sql
pg_globals_2025-04-12T09:25:48Z.sql
pg_globals_2025-04-12T09:26:34Z.sql
pg_settings_2025-04-12T09:25:17Z.out
pg_settings_2025-04-12T09:25:48Z.out
pg_settings_2025-04-12T09:26:34Z.out
postgres_2025-04-12T09:25:17Z.dump
postgres_2025-04-12T09:25:48Z.dump
postgres_2025-04-12T09:26:34Z.dump
```
