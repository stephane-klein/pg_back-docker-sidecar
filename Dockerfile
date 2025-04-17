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

RUN git clone --depth 1 --branch sklein-main https://github.com/stephane-klein/pg_back.git
RUN cd pg_back && CGO_ENABLED=0 go build -ldflags="-w -s" -o /go/bin/pg_back

FROM --platform=$BUILDPLATFORM alpine:3.21

RUN apk add --no-cache \
    bash \
    gomplate \
    postgresql-client # pg_back need pg_dump, then PostgreSQL version 17.4 is installed

COPY --from=build-stage --chmod=0755 /tmp/supercronic /usr/local/bin/supercronic
COPY --from=build-stage --chmod=0755 /go/bin/pg_back /usr/local/bin/pg_back

COPY ./pg_back.conf.tmpl /pg_back.conf.tmpl
COPY --chmod=0755 ./entrypoint.sh /entrypoint.sh

ENV POSTGRES_HOST="postres"
ENV POSTGRES_PORT="5432"
ENV POSTGRES_USER="postgres"
ENV POSTGRES_DBNAME="postgres"
ENV POSTGRES_PASSWORD="password"

# Daily
ENV BACKUP_CRON="0 3 * * *"
ENV DISABLE_CRON="false"

ENTRYPOINT [ "/entrypoint.sh" ]
