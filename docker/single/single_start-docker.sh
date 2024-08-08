#!/bin/bash -x

#saves current directory
current_dir=$(pwd)

#changes directory to the directory of the script
cd "$(dirname "$0")" || exit

# import from libs/common.sh
source ../common/common.sh

# concatenate envs with a pipe
envs=$(printf "%s|" "${allowed_envs[@]}")

# set env as first param or ask the user
if [ -z "$2" ]; then
  env=$(zenity --forms --title="Database install tool" \
    --text="This tool will spin up a docker container with a database optionally restoring a database dump for the specified version" \
    --add-combo="Database version" --combo-values="$envs")
else
  env=$2
fi

# ensure env is one of the allowed values
if [[ ! " ${allowed_envs[@]} " =~ " ${env} " ]]; then
  zenity --error --text="Invalid environment. Use one of the following:\n $envs"
  exit 1
fi

#if user presses cancel or esc button, exit
if [ -z "$env" ]
then
  echo "User cancelled"
  exit 1
fi

# replace dots and slashes with underscores
db=$(echo "dhis2_$env" | sed 's/[./]/_/g')

# use second args as "repopulate", or ask the user
if [ -z "$1" ]; then
  repopulate=$(zenity --question --text="Do you want to repopulate the database?")
else
  repopulate=$1
fi

# builds postgres image with citus and postgis extensions if it doesn't exist
if ! docker images | grep -q citus-postgis; then
  echo "Building docker image citus-postgis"
  docker build -t citus-postgis ../common/
fi

./single_stop_all_docker_containers.sh

container_name="$db""_single"

echo "Starting docker container $container_name"

# if container doesnt exists, create it
if ! docker ps -a | grep -q "$container_name"; then
  echo "Creating docker container $container_name"
  docker run\
   --name "$container_name"\
    -p 5432:5432\
    -v "$db":/var/lib/postgresql/data\
    -e POSTGRES_USER=postgres\
    -e PGUSER=postgres\
    -e POSTGRES_HOST_AUTH_METHOD=trust\
    -d \
   citus-postgis:latest
else
  echo "Docker container $container_name already exists"
  docker start "$container_name"
fi


# retry 15 times to check is postgres is up
for i in {1..15}
do
  if docker exec "$container_name" psql -U postgres -c "SELECT 1" &> /dev/null
  then
    echo "postgres is up"
    break
  fi
  echo "Waiting for postgres to start"
  sleep 1
done

# if repopulate is true, restore the database
if [ "$repopulate" = false ]; then
  echo "Restoring database wasn't requested, terminating"
  exit 0
fi

echo "Restoring database"

# restore the database
db_file_name="db.sql"
tmp_dir=$(mktemp -d)

chmod a+rwx "$tmp_dir"

url=https://databases.dhis2.org/sierra-leone/$env/dhis2-db-sierra-leone.sql.gz

# fetch the database
wget "$url" -O "$tmp_dir/$db_file_name"".gz" && gunzip "$tmp_dir/$db_file_name"".gz"

docker exec "$container_name" psql postgres -c "DROP EXTENSION IF EXISTS citus;"
docker exec "$container_name" psql postgres -c "DROP EXTENSION IF EXISTS postgis;"
docker exec "$container_name" psql postgres -c "DROP DATABASE IF EXISTS $db;"
docker exec "$container_name" psql postgres -c "CREATE DATABASE $db WITH OWNER dhis ENCODING 'UTF8';"
docker exec "$container_name" psql postgres -c "GRANT ALL PRIVILEGES ON DATABASE $db TO dhis;"
docker exec "$container_name" psql "$db" postgres -c "CREATE EXTENSION postgis;"

# restore the database from the dump
docker exec -i "$container_name" psql "$db" -U dhis <"$tmp_dir/$db_file_name"

# cleanup
rm -fr "$tmp_dir"

#changes directory back to the original directory
cd "$current_dir"
