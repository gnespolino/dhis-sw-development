FROM postgis/postgis:14-3.4 AS dhis2-postgres-base

RUN apt update \
    && apt -yqq upgrade \
    && apt-get -yqq install wget \
    && apt-get clean autoclean \
    && apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

ENV PGUSER=dhis
ENV POSTGRES_PASSWORD=postgres
ENV POSTGRES_USER=dhis
ENV POSTGRES_HOST_AUTH_METHOD=trust
ENV POSTGRES_DB=dhis

COPY pg_conf_parameters.sql /docker-entrypoint-initdb.d/999_initdb.sql

FROM dhis2-postgres-base AS dhis2-postgres

ARG DHIS2_VERSION=dev

RUN echo "${DHIS2_VERSION}" > /dhis2-db-version

RUN wget "https://databases.dhis2.org/sierra-leone/$DHIS2_VERSION/dhis2-db-sierra-leone.sql.gz" -O "/tmp/script.sql.gz" && gunzip "/tmp/script.sql.gz"
RUN mv /tmp/script.sql /docker-entrypoint-initdb.d/98_database_population.sql




