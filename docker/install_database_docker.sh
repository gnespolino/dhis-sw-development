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

docker exec -it citus_master psql -c "DROP DATABASE IF EXISTS $db;"
docker exec -it citus_master psql -c "CREATE DATABASE $db WITH OWNER dhis ENCODING 'UTF8';"
docker exec -it citus_master psql -c "SELECT run_command_on_workers(\$cmd\$ DROP DATABASE IF EXISTS $db \$cmd\$);"
docker exec -it citus_master psql -c "SELECT run_command_on_workers(\$cmd\$ CREATE DATABASE $db WITH OWNER dhis ENCODING 'UTF8' \$cmd\$);"
docker exec -it citus_master psql -c "GRANT ALL PRIVILEGES ON DATABASE $db TO dhis;"
docker exec -it citus_master psql "$db" -c "create extension citus;"
docker exec -it citus_master psql "$db" -c "create extension postgis;"
docker exec -i  citus_master psql "$db" -U dhis <$tmp_dir/$db_file_name

rm -fr $tmp_dir
