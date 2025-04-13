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
[+] Running 8/8
 ✔ Container poc_pg_back_66ce9ade1421-postgres2-1  Removed                 0.4s
 ✔ Container poc_pg_back_66ce9ade1421-pg_back-1    Removed                10.2s
 ✔ Container poc_pg_back_66ce9ade1421-postgres1-1  Removed                 0.3s
 ✔ Container poc_pg_back_66ce9ade1421-minio-1      Removed                 0.4s
 ✔ Volume poc_pg_back_66ce9ade1421_postgres1       Removed                 0.1s
 ✔ Volume poc_pg_back_66ce9ade1421_postgres2       Removed                 0.0s
 ✔ Volume poc_pg_back_66ce9ade1421_minio           Removed                 0.1s
 ✔ Network poc_pg_back_66ce9ade1421_default        Removed                 0.3s
```

I start the services:

- `postgres1`, which is the PostgreSQL instance I want to backup
- `minio` which serves as a local Object Storage
- `pg_back` a "Sidecar" Docker container that executes the [`pg_back`](https://github.com/orgrim/pg_back/) commands and runs them daily with [supercronic](https://github.com/aptible/supercronic)

```sh
$ docker compose up -d postgres1 minio pg_back --wait
[+] Running 6/6
 ✔ Network poc_pg_back_66ce9ade1421_default        Created                 0.2s
 ✔ Volume "poc_pg_back_66ce9ade1421_postgres1"     Created                 0.0s
 ✔ Volume "poc_pg_back_66ce9ade1421_minio"         Created                 0.0s
 ✔ Container poc_pg_back_66ce9ade1421-minio-1      Healthy                 6.6s
 ✔ Container poc_pg_back_66ce9ade1421-postgres1-1  Healthy                 6.6s
 ✔ Container poc_pg_back_66ce9ade1421-pg_back-1    Healthy                 6.4s
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
2025/04/13 09:08:50 INFO: dumping globals
2025/04/13 09:08:50 INFO: dumping instance configuration
2025/04/13 09:08:50 INFO: encrypting /var/backups/postgresql/pg_globals_2025-04-13T09:08:50Z.sql
2025/04/13 09:08:50 INFO: uploading /var/backups/postgresql/pg_globals_2025-04-13T09:08:50Z.sql.age to S3 bucket pg-back
2025/04/13 09:08:50 INFO: encrypting /var/backups/postgresql/pg_settings_2025-04-13T09:08:50Z.out
2025/04/13 09:08:50 INFO: encrypting /var/backups/postgresql/hba_file_2025-04-13T09:08:50Z.out
2025/04/13 09:08:50 INFO: uploading /var/backups/postgresql/pg_settings_2025-04-13T09:08:50Z.out.age to S3 bucket pg-back
2025/04/13 09:08:50 INFO: dumping database postgres
2025/04/13 09:08:50 INFO: encrypting /var/backups/postgresql/ident_file_2025-04-13T09:08:50Z.out
2025/04/13 09:08:50 INFO: uploading /var/backups/postgresql/hba_file_2025-04-13T09:08:50Z.out.age to S3 bucket pg-back
2025/04/13 09:08:50 INFO: uploading /var/backups/postgresql/ident_file_2025-04-13T09:08:50Z.out.age to S3 bucket pg-back
2025/04/13 09:08:50 INFO: dump of postgres to /var/backups/postgresql/postgres_2025-04-13T09:08:50Z.dump done
2025/04/13 09:08:50 INFO: encrypting /var/backups/postgresql/postgres_2025-04-13T09:08:50Z.dump
2025/04/13 09:08:50 INFO: uploading /var/backups/postgresql/postgres_2025-04-13T09:08:50Z.dump.age to S3 bucket pg-back
2025/04/13 09:08:50 INFO: waiting for postprocessing to complete
2025/04/13 09:08:50 INFO: purging old dumps
```

I wait a few seconds (30s) before injecting more data into `postgres1` and performing a new dump:

```sh
$ ./scripts/generate_dummy_rows_in_postgres1.sh 1000
$ ./scripts/execute-pg_back-dump.sh
2025/04/13 09:09:21 INFO: dumping globals
2025/04/13 09:09:21 INFO: dumping instance configuration
2025/04/13 09:09:21 INFO: encrypting /var/backups/postgresql/pg_globals_2025-04-13T09:09:21Z.sql
2025/04/13 09:09:21 INFO: uploading /var/backups/postgresql/pg_globals_2025-04-13T09:09:21Z.sql.age to S3 bucket pg-back
2025/04/13 09:09:21 INFO: encrypting /var/backups/postgresql/pg_settings_2025-04-13T09:09:21Z.out
2025/04/13 09:09:21 INFO: encrypting /var/backups/postgresql/hba_file_2025-04-13T09:09:21Z.out
2025/04/13 09:09:21 INFO: uploading /var/backups/postgresql/pg_settings_2025-04-13T09:09:21Z.out.age to S3 bucket pg-back
2025/04/13 09:09:21 INFO: dumping database postgres
2025/04/13 09:09:21 INFO: encrypting /var/backups/postgresql/ident_file_2025-04-13T09:09:21Z.out
2025/04/13 09:09:21 INFO: uploading /var/backups/postgresql/hba_file_2025-04-13T09:09:21Z.out.age to S3 bucket pg-back
2025/04/13 09:09:21 INFO: uploading /var/backups/postgresql/ident_file_2025-04-13T09:09:21Z.out.age to S3 bucket pg-back
2025/04/13 09:09:21 INFO: dump of postgres to /var/backups/postgresql/postgres_2025-04-13T09:09:21Z.dump done
2025/04/13 09:09:21 INFO: encrypting /var/backups/postgresql/postgres_2025-04-13T09:09:21Z.dump
2025/04/13 09:09:21 INFO: uploading /var/backups/postgresql/postgres_2025-04-13T09:09:21Z.dump.age to S3 bucket pg-back
2025/04/13 09:09:21 INFO: waiting for postprocessing to complete
2025/04/13 09:09:21 INFO: purging old dumps
```

Here is the list of files uploaded to Minio Object Storage:

```sh
$ ./scripts/execute-pg_back-list-remote.sh
foobar/hba_file_2025-04-13T09:08:50Z.out.age
foobar/hba_file_2025-04-13T09:09:21Z.out.age
foobar/ident_file_2025-04-13T09:08:50Z.out.age
foobar/ident_file_2025-04-13T09:09:21Z.out.age
foobar/pg_globals_2025-04-13T09:08:50Z.sql.age
foobar/pg_globals_2025-04-13T09:09:21Z.sql.age
foobar/pg_settings_2025-04-13T09:08:50Z.out.age
foobar/pg_settings_2025-04-13T09:09:21Z.out.age
foobar/postgres_2025-04-13T09:08:50Z.dump.age
foobar/postgres_2025-04-13T09:09:21Z.dump.age
```

I observe something I don't like. Each backup consists of 5 files. These files are not grouped in a folder.
I find this makes reading the list of backups difficult.

I also observe that the `ENCRYPT: "true"` parameter has been taken into account, the archive files appear to be encrypted with Age.

Another thing I don't like is that I notice that the archives are still present in the container,
even after being uploaded to Object Storage:

```sh
$ docker compose exec pg_back ls /var/backups/postgresql/ -1
hba_file_2025-04-13T09:08:50Z.out.age
hba_file_2025-04-13T09:09:21Z.out.age
ident_file_2025-04-13T09:08:50Z.out.age
ident_file_2025-04-13T09:09:21Z.out.age
pg_globals_2025-04-13T09:08:50Z.sql.age
pg_globals_2025-04-13T09:09:21Z.sql.age
pg_settings_2025-04-13T09:08:50Z.out.age
pg_settings_2025-04-13T09:09:21Z.out.age
postgres_2025-04-13T09:08:50Z.dump.age
postgres_2025-04-13T09:09:21Z.dump.age
```

I now wait 45s before injecting data and performing a new dump.
This 45s waiting period allows me to observe if the `PURGE_OLDER_THAN: "60s"` parameter is
correctly taken into account by `pg_back`.

```sh
$ ./scripts/generate_dummy_rows_in_postgres1.sh 1000
$ ./scripts/execute-pg_back-dump.sh
2025/04/13 09:10:07 INFO: dumping globals
2025/04/13 09:10:07 INFO: dumping instance configuration
2025/04/13 09:10:07 INFO: encrypting /var/backups/postgresql/pg_globals_2025-04-13T09:10:07Z.sql
2025/04/13 09:10:07 INFO: uploading /var/backups/postgresql/pg_globals_2025-04-13T09:10:07Z.sql.age to S3 bucket pg-back
2025/04/13 09:10:07 INFO: encrypting /var/backups/postgresql/pg_settings_2025-04-13T09:10:07Z.out
2025/04/13 09:10:07 INFO: encrypting /var/backups/postgresql/hba_file_2025-04-13T09:10:07Z.out
2025/04/13 09:10:07 INFO: uploading /var/backups/postgresql/pg_settings_2025-04-13T09:10:07Z.out.age to S3 bucket pg-back
2025/04/13 09:10:07 INFO: dumping database postgres
2025/04/13 09:10:07 INFO: uploading /var/backups/postgresql/hba_file_2025-04-13T09:10:07Z.out.age to S3 bucket pg-back
2025/04/13 09:10:07 INFO: encrypting /var/backups/postgresql/ident_file_2025-04-13T09:10:07Z.out
2025/04/13 09:10:07 INFO: uploading /var/backups/postgresql/ident_file_2025-04-13T09:10:07Z.out.age to S3 bucket pg-back
2025/04/13 09:10:07 INFO: dump of postgres to /var/backups/postgresql/postgres_2025-04-13T09:10:07Z.dump done
2025/04/13 09:10:07 INFO: encrypting /var/backups/postgresql/postgres_2025-04-13T09:10:07Z.dump
2025/04/13 09:10:07 INFO: uploading /var/backups/postgresql/postgres_2025-04-13T09:10:07Z.dump.age to S3 bucket pg-back
2025/04/13 09:10:07 INFO: waiting for postprocessing to complete
2025/04/13 09:10:07 INFO: purging old dumps
2025/04/13 09:10:07 INFO: removing /var/backups/postgresql/postgres_2025-04-13T09:08:50Z.dump.age
2025/04/13 09:10:07 INFO: removing remote foobar/postgres_2025-04-13T09:08:50Z.dump.age
2025/04/13 09:10:07 INFO: removing /var/backups/postgresql/pg_globals_2025-04-13T09:08:50Z.sql.age
2025/04/13 09:10:07 INFO: removing remote foobar/pg_globals_2025-04-13T09:08:50Z.sql.age
2025/04/13 09:10:07 INFO: removing /var/backups/postgresql/pg_settings_2025-04-13T09:08:50Z.out.age
2025/04/13 09:10:07 INFO: removing remote foobar/pg_settings_2025-04-13T09:08:50Z.out.age
2025/04/13 09:10:07 INFO: removing /var/backups/postgresql/hba_file_2025-04-13T09:08:50Z.out.age
2025/04/13 09:10:07 INFO: removing remote foobar/hba_file_2025-04-13T09:08:50Z.out.age
2025/04/13 09:10:07 INFO: removing /var/backups/postgresql/ident_file_2025-04-13T09:08:50Z.out.age
2025/04/13 09:10:07 INFO: removing remote foobar/ident_file_2025-04-13T09:08:50Z.out.age
```

I check that the first archive has been deleted:

```sh
$ ./scripts/execute-pg_back-list-remote.sh
foobar/hba_file_2025-04-13T09:09:21Z.out.age
foobar/hba_file_2025-04-13T09:10:07Z.out.age
foobar/ident_file_2025-04-13T09:09:21Z.out.age
foobar/ident_file_2025-04-13T09:10:07Z.out.age
foobar/pg_globals_2025-04-13T09:09:21Z.sql.age
foobar/pg_globals_2025-04-13T09:10:07Z.sql.age
foobar/pg_settings_2025-04-13T09:09:21Z.out.age
foobar/pg_settings_2025-04-13T09:10:07Z.out.age
foobar/postgres_2025-04-13T09:09:21Z.dump.age
foobar/postgres_2025-04-13T09:10:07Z.dump.age
```

This is how to download the latest archive locally:

```sh
./scripts/download-dump.sh 2025-04-13T09:10:07
download: s3://pg-back/foobar/hba_file_2025-04-13T09:10:07Z.out.age to tmp-downloads-dump/hba_file_2025-04-13T09:10:07Z.out.age
download: s3://pg-back/foobar/pg_globals_2025-04-13T09:10:07Z.sql.age to tmp-downloads-dump/pg_globals_2025-04-13T09:10:07Z.sql.age
download: s3://pg-back/foobar/ident_file_2025-04-13T09:10:07Z.out.age to tmp-downloads-dump/ident_file_2025-04-13T09:10:07Z.out.age
download: s3://pg-back/foobar/pg_settings_2025-04-13T09:10:07Z.out.age to tmp-downloads-dump/pg_settings_2025-04-13T09:10:07Z.out.age
download: s3://pg-back/foobar/postgres_2025-04-13T09:10:07Z.dump.age to tmp-downloads-dump/postgres_2025-04-13T09:10:07Z.dump.age
```

Les archives ont été download dans `./tmp-downloads-dump/`:

```sh
$ ls -lha ./tmp-downloads-dump/
total 40K
drwxr-xr-x 1 stephane stephane  424 13 avril 11:10 .
drwxr-xr-x 1 stephane stephane  244 13 avril 10:59 ..
-rw-r--r-- 1 stephane stephane   13 13 avril 10:42 .gitignore
-rw-r--r-- 1 stephane stephane 5,9K 13 avril 11:10 hba_file_2025-04-13T09:10:07Z.out.age
-rw-r--r-- 1 stephane stephane 2,9K 13 avril 11:10 ident_file_2025-04-13T09:10:07Z.out.age
-rw-r--r-- 1 stephane stephane  719 13 avril 11:10 pg_globals_2025-04-13T09:10:07Z.sql.age
-rw-r--r-- 1 stephane stephane  574 13 avril 11:10 pg_settings_2025-04-13T09:10:07Z.out.age
-rw-r--r-- 1 stephane stephane 8,5K 13 avril 11:10 postgres_2025-04-13T09:10:07Z.dump.age
-rw-r--r-- 1 stephane stephane   46 12 avril 17:48 README.md
```

Decrypting `*.age` archives with Age:

```sh
$ ./scripts/age-decrypt-downloads-dump.sh
```

I start the `postgres2` instance where I want to restore the backups:

```sh
$ docker compose up -d postgres2 --wait
[+] Running 2/2
 ✔ Volume "poc_pg_back_66ce9ade1421_postgres2"     Created                 0.0s
 ✔ Container poc_pg_back_66ce9ade1421-postgres2-1  Healthy                 5.7s
```
Import `2025-04-13T09:10:07` local archive to `postgres2`:
```sh
$ ./scripts/postgres2-import-local-dump.sh 2025-04-13T09:10:07
[+] Copying 1/1
 ✔ poc_pg_back_66ce9ade1421-postgres2-1 copy ./tmp-downloads-dump/pg_globals_2025-04-13T09:10:07Z.sql to poc_pg_back_66ce9ade1421-postgres2-1:/pg_globals.sql Copied0.0s
[+] Copying 1/1
 ✔ poc_pg_back_66ce9ade1421-postgres2-1 copy ./tmp-downloads-dump/postgres_2025-04-13T09:10:07Z.dump to poc_pg_back_66ce9ade1421-postgres2-1:/postgres.dump Copied0.0s
```

Now I check that the `dummy` table and its data have been correctly restored in the `postgres2` instance:

```sh
$ echo "select count(*) from dummy;" | ./scripts/postgres2-sql.sh
 count
-------
  2100
(1 row)

```
