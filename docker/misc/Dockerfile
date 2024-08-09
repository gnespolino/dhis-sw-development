FROM postgis/postgis:14-3.4 AS dhis2-postgres-base

RUN apt update && apt -yqq upgrade && apt-get -yqq install wget

# adds the dhis user and database by writing to the inidb.d directory
RUN echo "CREATE ROLE dhis WITH SUPERUSER CREATEDB CREATEROLE LOGIN ENCRYPTED PASSWORD 'password';" > /docker-entrypoint-initdb.d/11_create_role.sql
RUN echo "ALTER SYSTEM SET max_connections = 1000;" > /docker-entrypoint-initdb.d/12_max_connections.sql
RUN echo "ALTER SYSTEM SET shared_buffers = '512MB';" > /docker-entrypoint-initdb.d/13_shared_buffers.sql
RUN echo "ALTER SYSTEM SET max_wal_size = '2GB';" > /docker-entrypoint-initdb.d/14_max_wal_size.sql
RUN echo "CREATE DATABASE dhis WITH OWNER dhis ENCODING 'UTF8' TEMPLATE template_postgis;" > /docker-entrypoint-initdb.d/15_create_db.sql
RUN echo "GRANT ALL PRIVILEGES ON DATABASE dhis TO dhis;" > /docker-entrypoint-initdb.d/16_grant_privileges.sql

FROM dhis2-postgres-base AS dhis2-postgres

ENV PGUSER=postgres
ENV POSTGRES_PASSWORD=postgres
ENV POSTGRES_USER=postgres
ENV POSTGRES_HOST_AUTH_METHOD=trust

ARG DHIS2_VERSION=dev

RUN echo "${DHIS2_VERSION}" > /dhis2-db-version

RUN wget "https://databases.dhis2.org/sierra-leone/$DHIS2_VERSION/dhis2-db-sierra-leone.sql.gz" -O "/tmp/script.sql.gz" && gunzip "/tmp/script.sql.gz"

RUN echo "\\\\c dhis" > /tmp/prepend.sql
RUN cat /tmp/prepend.sql /tmp/script.sql >> /docker-entrypoint-initdb.d/98_database_population.sql

RUN rm /tmp/script.sql /tmp/prepend.sql
