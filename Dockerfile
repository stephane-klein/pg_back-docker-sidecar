# syntax=docker/dockerfile:1

FROM --platform=${BUILDPLATFORM:-linux/amd64} golang:1.24.2-alpine3.21 AS build-stage

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

ARG SUPERCRONIC_VERSION=0.2.33

RUN apk add --no-cache git zip curl \
# Install supercronic
&& curl -fsSLO "https://github.com/aptible/supercronic/releases/download/v${SUPERCRONIC_VERSION}/supercronic-${TARGETOS}-${TARGETARCH}" \
&& mv "supercronic-${TARGETOS}-${TARGETARCH}" "/tmp/supercronic"

WORKDIR /go


RUN git clone --branch master https://github.com/orgrim/pg_back.git
RUN cd pg_back && git checkout 5375ec26a6e8453ec843e31ed116c6b35774e3a9 && CGO_ENABLED=0 go build -ldflags="-w -s" -o /go/bin/pg_back

FROM --platform=$BUILDPLATFORM alpine:3.21

# pg_back need pg_dump, then PostgreSQL client packages are installed
# Multiple PostgreSQL versions are provided because for example a backup
# made with Postgres17 cannot be restored on an instance running version 16
RUN apk add --no-cache \
    bash=5.2.37-r0 \
    gomplate=4.2.0-r5 \
    postgresql17-client=17.5-r0 \
    postgresql16-client=16.9-r0 \
    postgresql15-client=15.13-r0

COPY --from=build-stage --chmod=0755 /tmp/supercronic /usr/local/bin/supercronic
COPY --from=build-stage --chmod=0755 /go/bin/pg_back /usr/local/bin/pg_back

COPY ./pg_back.conf.tmpl /pg_back.conf.tmpl
COPY --chmod=0755 ./entrypoint.sh /entrypoint.sh

ENV POSTGRES_VERSION=17
ENV POSTGRES_HOST="postres"
ENV POSTGRES_PORT="5432"
ENV POSTGRES_USER="postgres"
ENV POSTGRES_DBNAME="postgres"
ENV POSTGRES_PASSWORD="password"

# Daily
ENV BACKUP_CRON="0 3 * * *"
ENV DISABLE_CRON="false"

ENTRYPOINT [ "/entrypoint.sh" ]
