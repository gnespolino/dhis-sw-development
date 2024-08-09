#!/bin/bash

#saves current directory
current_dir=$(pwd)

#changes directory to the directory of the script
cd "$(dirname "$0")" || exit

source ../common/common.sh

for allowed_env in "${allowed_envs[@]}"; do
  echo "building docker image for $allowed_env"
  build_docker_image "$allowed_env" "$DHIS2_DB_IMAGE_NAME"
done

cd "$current_dir" || exit