#!/bin/bash

# verify parameter 1 is not in env array
env=$1
declare -a envs=("dev" "2.39" "2.40" "2.41" "2.39.0/analytics_be" "2.39.0.1/analytics_be")

#ensure env is in envs array
if [[ ! " ${envs[@]} " =~ " ${env} " ]]; then
  echo "Invalid environment. Use one of the following: ${envs[@]}"
  exit 1
fi

# all other parameters after the first one are collected into an array called args
args=("$@")
# remove the first element from the args array
args=("${args[@]:1}")
echo "workers: ${args[@]}"

#ensure workers are reachable
for worker in "${args[@]}"
do
  if ! ping -c 1 $worker &> /dev/null
  then
    echo "$worker is unreachable"
    exit 1
  fi
done

db=dhis2_$env
url=https://databases.dhis2.org/sierra-leone/$env/dhis2-db-sierra-leone.sql.gz

# replace dots and slashes with underscores
db="${db//./_}"
db="${db//\//_}"

# fetch the database
db_file_name="db.sql"
tmp_dir=$(mktemp -d)

wget $url -O ${tmp_dir}/${db_file_name}".gz" && gunzip $tmp_dir/$db_file_name".gz"

# as user postgres, execute the following commands
# drop the database if it exists
# create the database with owner dhis
# create the postgis extension
# create the citus extension
# grant all privileges on the database to dhis
# restore the database from the dump
# setup the worker
psql postgres postgres << END_OF_SCRIPT
DROP DATABASE IF EXISTS $db;
CREATE DATABASE $db WITH OWNER dhis  ENCODING 'UTF8';
GRANT ALL PRIVILEGES ON DATABASE $db TO dhis;
\c $db
CREATE EXTENSION postgis;
CREATE EXTENSION citus;
SELECT citus_set_coordinator_host('$HOSTNAME', 5432);
\q
END_OF_SCRIPT
echo "database $db created"
for worker in "${args[@]}"
do
  echo "working on $worker"
  # sends commands to the worker through ssh
  ssh $worker "psql postgres postgres << END_OF_SCRIPT
DROP DATABASE IF EXISTS $db;
CREATE DATABASE $db WITH OWNER dhis ENCODING 'UTF8';
GRANT ALL PRIVILEGES ON DATABASE $db TO dhis;
\c $db
CREATE EXTENSION postgis;
CREATE EXTENSION citus;
END_OF_SCRIPT"
  echo "database $db created on $worker"
  #adds the new node to the citus cluster
  psql $db -U postgres <<END_OF_SCRIPT
SELECT * from citus_add_node('$worker', 5432);
END_OF_SCRIPT
  echo "node $worker added to citus cluster"
done

#loads the sql script into the master node
psql "$db" -U dhis <$tmp_dir/$db_file_name
rm $tmp_dir/$db_file_name
