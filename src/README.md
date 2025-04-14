# Build custom pg_back in Docker image

Here is the method I follow when I want to compile a customized version of [pg_back](https://github.com/orgrim/pg_back/) and incorporate this compiled binary into the Docker image of the repository.

Install workspace dependencies with *Mise*:

```sh
$ mise install
```

Install last version of "[PostgreSQL Client Applications](https://www.postgresql.org/docs/17/reference-client.html)" on your OS. The following commands are required: `pg_dump`, `pg_dumpall`.
[For example, you can follow these instructions](https://www.postgresql.org/docs/17/reference-client.html).

I initialize the `postgres1`, `postgres2`, `minio` services defined in the parent folder and inject dummy data.

```
$ ./scripts/init.sh
```

I start by generating the `pg_back_*.conf` configuration files:

```sh
$ ./scripts/generate_pg_back_conf_files.sh
```

Then I clone the `pg_back` repository and compile the project:

```sh
$ git clone git@github.com:orgrim/pg_back.git ./github.com/orgrim/pg_back
$ cd ./github.com/orgrim/pg_back
$ make pg_back
```

I start by emptying *Minio* and the local folder used by *pg_back*:

```sh
$ ../../../../scripts/aws-s3-local-minio.sh s3 rm s3://pg-back --recursive
$ rm -rf ../../../tmp-pg_back
```

I run a backup:

```
$ ./pg_back -c ../../../pg_back_postgres1.conf
...
```

Then I check the contents present in *Minio*:

```sh
$ ../../../../scripts/aws-s3-local-minio.sh s3 ls s3://pg-back --recursive
2025-04-14 12:36:57       5989 foobar/hba_file_2025-04-14T12:36:57+02:00.out.age
2025-04-14 12:36:57       2888 foobar/ident_file_2025-04-14T12:36:57+02:00.out.age
2025-04-14 12:36:57        719 foobar/pg_globals_2025-04-14T12:36:57+02:00.sql.age
2025-04-14 12:36:57        574 foobar/pg_settings_2025-04-14T12:36:57+02:00.out.age
2025-04-14 12:36:58       8682 foobar/postgres_2025-04-14T12:36:57+02:00.dump.age
```

Everything worked well.

## Build `stephaneklein/pg_back:wip` with custom `pg_back`

Here is a method to build a Docker image `stephaneklein/pg_back:wip` incorporating the `./github.com/orgrim/pg_back/pg_back` binary.

```sh
$ docker build -f ../Dockerfile.dev ../ -t stephaneklein/pg_back:wip
$ docker run --rm -it stephaneklein/pg_back:wip pg_back --version
pg_back version 2.6.0
```
