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
echo "deleting ${DHIS2_DB_IMAGE_NAME}-$docker_tag"

# stops any instances of the container
containers=$(docker ps -a | grep ${DHIS2_DB_IMAGE_NAME}-"$docker_tag" | awk '{print $1}')
for container in $containers; do
  echo "stopping container $container"
  docker stop "$container" --signal KILL || true
  docker rm "$container" --force || true
done

# removes the image
image=$(docker images ${DHIS2_DB_IMAGE_NAME} | grep "$docker_tag" | awk '{print $3}')
echo "deleting image $image"
docker rmi "$image" --force || true
if [ "$env" == "dev" ]; then
  echo "deleting ${DHIS2_DB_IMAGE_NAME}:latest"
  docker rmi ${DHIS2_DB_IMAGE_NAME}:latest --force || true
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

echo "Building ${DHIS2_DB_IMAGE_NAME}:$docker_tag"

docker build -t ${DHIS2_DB_IMAGE_NAME}:"$docker_tag" --build-arg="DHIS2_VERSION=$env" .
docker tag ${DHIS2_DB_IMAGE_NAME}:"$docker_tag" gnespolino/${DHIS2_DB_IMAGE_NAME}:"$docker_tag"

if [ "$env" == "dev" ]; then
  docker tag ${DHIS2_DB_IMAGE_NAME}:"$docker_tag" ${DHIS2_DB_IMAGE_NAME}:latest
  docker tag ${DHIS2_DB_IMAGE_NAME}:latest gnespolino/${DHIS2_DB_IMAGE_NAME}:latest
fi
