#!/bin/bash -x

set -e
set -u

db_file_name="db.sql"
tmp_dir=$(mktemp -d)

chmod a+rwx $tmp_dir

env=$(kdialog --default "dev" --combobox "Select a flavour:" "dev" "2.35" "2.36" "2.37" "2.38" "2.39" "2.40" "2.41" "2.39.0/analytics_be" "2.39.0.1/analytics_be")

# if env is unset or empty (user pressed cancel or esc button), exit
if [ -z "$env" ]
then
  exit 1
else
  db=dhis2_$env
  url=https://databases.dhis2.org/sierra-leone/$env/dhis2-db-sierra-leone.sql.gz
fi

# replace dots and slashes with underscores
db="${db//./_}"
db="${db//\//_}"

# fetch the database
wget $url -O ${tmp_dir}/${db_file_name}".gz" && gunzip $tmp_dir/$db_file_name".gz"

declare -a containers=("citus_master" "citus-worker-1")

for container in "${containers[@]}"
do
  docker exec $container psql postgres -c "DROP EXTENSION IF EXISTS citus;"
  docker exec $container psql postgres -c "DROP EXTENSION IF EXISTS postgis;"
  docker exec $container psql postgres -c "DROP DATABASE IF EXISTS $db;"
  docker exec $container psql postgres -c "CREATE DATABASE $db WITH OWNER dhis ENCODING 'UTF8';"
  docker exec $container psql postgres -c "GRANT ALL PRIVILEGES ON DATABASE $db TO dhis;"
  docker exec $container psql $db postgres -c "CREATE EXTENSION citus;"
  docker exec $container psql $db postgres -c "CREATE EXTENSION postgis;"
done

# setup the master node
docker exec citus_master psql $db postgres -c "SELECT citus_set_coordinator_host('master', 5432);"
# register the worker node
docker exec citus_master psql $db postgres -c "SELECT * from citus_add_node('worker', 5432)"

# restore the database from the dump
docker exec -i citus_master psql "$db" -U dhis <$tmp_dir/$db_file_name

# cleanup
rm -fr $tmp_dir
