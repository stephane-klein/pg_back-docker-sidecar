# syntax=docker/dockerfile:1

ARG ALPINE_VERSION=3.21

FROM alpine:$ALPINE_VERSION AS BASE

ARG TARGETOS
ARG TARGETARCH

ARG SUPERCRONIC_VERSION=0.2.33
ARG PG_BACK_VERSION=2.5.0

RUN apk add --no-cache zip curl \
    # Install supercronic
    && curl -fsSLO "https://github.com/aptible/supercronic/releases/download/v${SUPERCRONIC_VERSION}/supercronic-${TARGETOS}-${TARGETARCH}" \
        && mv "supercronic-${TARGETOS}-${TARGETARCH}" "/tmp/supercronic" \
    # Install pg_pack
    && wget -O "/tmp/pg_back.tar.gz" https://github.com/orgrim/pg_back/releases/download/v${PG_BACK_VERSION}/pg_back_${PG_BACK_VERSION}_linux_amd64.tar.gz \
        && tar xfz "/tmp/pg_back.tar.gz" -C /tmp/

FROM --platform=$BUILDPLATFORM alpine:$ALPINE_VERSION

RUN apk add --no-cache \
    bash \
    gomplate \
    postgresql-client # pg_back need pg_dump, then PostgreSQL version 17.4 is installed

COPY --from=BASE --chmod=0755 /tmp/supercronic /usr/local/bin/supercronic
COPY --from=BASE --chmod=0755 /tmp/pg_back /usr/local/bin/pg_back

COPY ./pg_back.conf.tmpl /pg_back.conf.tmpl
COPY --chmod=0755 ./entrypoint.sh /entrypoint.sh

ENV POSTGRES_HOST="postres"
ENV POSTGRES_PORT="5432"
ENV POSTGRES_USER="postgres"
ENV POSTGRES_DBNAME="postgres"
ENV POSTGRES_PASSWORD="password"

# Daily
ENV BACKUP_CRON="0 3 * * *"

ENTRYPOINT [ "/entrypoint.sh" ]
