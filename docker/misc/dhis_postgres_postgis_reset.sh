#!/bin/bash

#saves current directory
current_dir=$(pwd)

#changes directory to the directory of the script
cd "$(dirname "$0")" || exit

source ../common/common.sh

# set env as second param or ask the user
if [ -z "$1" ]; then
  env=$(choose_env)
else
  env=$1
fi

check_env "$env"

echo "building docker image for $env"

#remoives slash from the env
docker_tag=$(normalize_docker_tag "$env")

# delete the image if it exists
echo "deleting dhis-postgres-postgis-$docker_tag"

# stops any instances of the container
containers=$(docker ps -a | grep dhis-postgres-postgis-"$docker_tag" | awk '{print $1}')
for container in $containers; do
  echo "stopping container $container"
  docker stop "$container" --signal KILL || true
  docker rm "$container" --force || true
done

# removes the image
image=$(docker images dhis-postgres-postgis | grep "$docker_tag" | awk '{print $3}')
echo "deleting image $image"
docker rmi "$image" --force || true
if [ "$env" == "dev" ]; then
  echo "deleting dhis-postgres-postgis:latest"
  docker rmi dhis-postgres-postgis:latest --force || true
fi

# retries 5 times to remove the volumes until there are no more
for i in {1..5}; do
  echo "pruning volumes, attempt $i"
  docker volume prune -a --force || true
  # if deleted all volumes, break the loop
  if [ -z "$(docker volume ls | grep dhis2_$docker_tag)" ]; then
    echo "all volumes deleted"
    break
  fi
done

echo "building dhis-postgres-postgis:$docker_tag"
#if env is dev tag the image also with latest
if [ "$env" == "dev" ]; then
  echo
  docker build -t dhis-postgres-postgis:"$docker_tag" -t dhis-postgres-postgis:latest --build-arg="DHIS2_VERSION=$env" .
else
  echo
  docker build -t dhis-postgres-postgis:"$docker_tag" --build-arg="DHIS2_VERSION=$env" .
fi
