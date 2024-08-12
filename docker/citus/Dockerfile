FROM citusdata/citus:postgres_14 AS citus-base

RUN apt update \
    && apt -yqq upgrade \
    && apt-get -yqq install gnupg2 wget curl jq \
    && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && apt-get install -yqq postgis postgresql-14-postgis-3 \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

COPY ./docker-image-scripts/create_dhis_schema.sql /docker-entrypoint-initdb.d/998_create_dhis_schema.sql
COPY ./docker-image-scripts/script_for_master.sh /docker-entrypoint-initdb.d/999_master.sh

FROM citus-base AS dhis2-citus

ENV PGUSER=postgres
ENV POSTGRES_PASSWORD=postgres
ENV POSTGRES_USER=postgres
ENV POSTGRES_HOST_AUTH_METHOD=trust

ARG DHIS2_VERSION=dev

RUN echo "${DHIS2_VERSION}" > /dhis2-db-version

RUN wget "https://databases.dhis2.org/sierra-leone/$DHIS2_VERSION/dhis2-db-sierra-leone.sql.gz" -O "/tmp/script.sql.gz" && gunzip "/tmp/script.sql.gz" && chmod 777 "/tmp/script.sql"

