#!/bin/bash

#saves current directory
current_dir=$(pwd)

#changes directory to the directory of the script
cd "$(dirname "$0")" || exit

# import from libs/common.sh
source ../common/common.sh

# set env as second param or ask the user
if [ -z "$2" ]; then
  env=$(choose_env)
else
  env=$2
fi

# ensure env is one of the allowed values
check_env "$env"

# replace dots and slashes with underscores
db=$(normalize_db_name "$env")

# use first arg as "repopulate", or ask the user
if [ -z "$1" ]; then
  repopulate=$(ask_repopulate)
else
  repopulate=$1
fi

docker_tag=$(normalize_docker_tag "$env")
container_name=${DHIS2_DB_IMAGE_NAME}-"$docker_tag"

# if repopulate is true, remove the database volume
if [ "$repopulate" == "true" ]; then
  ./dhis_postgres_postgis_reset.sh "$env"
else
  if docker ps | grep -q "${container_name}"; then
    echo "Container ${DHIS2_DB_IMAGE_NAME}-$env is already running"
    exit 0
  fi
fi

build_docker_image "$env" "$DHIS2_DB_IMAGE_NAME"

stop_all_containers

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
   ${DHIS2_DB_IMAGE_NAME}:"$docker_tag"
else
  echo "Docker container $container_name already exists"
  docker start "$container_name"
fi

pg_is_up=false # postgres is not up yet

# waits for postgres to finish initdb
for i in {1..100}
do
  # gets the pids of running postgres in the container which is a list of space separated pids
  pg_pids=$(docker exec $container_name pidof postgres)" "

  if [[ $pg_pids == *" 1 "* ]]
  then
    echo "postgres is up"
    pg_is_up=true
    break
  fi
  echo "Waiting for postgres to start [$i/100]"
  sleep 3
done

if [ "$pg_is_up" = false ]; then
  echo "postgres failed to start"
  exit 1
fi

#changes directory back to the original directory
cd "$current_dir" || exit

# if exists notofy-send command, send a notification
send_notification "DHIS DB Container Started"  "<p>--</p><br/>Name: <b>($container_name)</b><br/>--<br/>Version: <b>$env</b>"
