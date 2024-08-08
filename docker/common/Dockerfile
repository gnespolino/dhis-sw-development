FROM citusdata/citus:postgres_14

RUN apt update && apt -yqq upgrade

RUN apt-get -yqq install gnupg2 wget
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

RUN apt-get install -yqq postgis postgresql-14-postgis-3

RUN apt-get clean autoclean
RUN apt-get autoremove --yes
RUN rm -rf /var/lib/{apt,dpkg,cache,log}/

# adds the dhis user and database by writing to the inidb.d directory
RUN echo "CREATE ROLE dhis WITH SUPERUSER CREATEDB CREATEROLE LOGIN ENCRYPTED PASSWORD 'password';" > /docker-entrypoint-initdb.d/02_create_role.sql
RUN echo "ALTER SYSTEM SET max_connections = 1000;" > /docker-entrypoint-initdb.d/03_max_connections.sql
RUN echo "ALTER SYSTEM SET shared_buffers = '512MB';" > /docker-entrypoint-initdb.d/04_shared_buffers.sql
RUN echo "ALTER SYSTEM SET max_wal_size = '2GB';" > /docker-entrypoint-initdb.d/05_max_wal_size.sql