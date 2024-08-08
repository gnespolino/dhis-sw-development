#!/bin/bash

#saves current directory
current_dir=$(pwd)

#changes directory to the directory of the script
cd "$(dirname "$0")" || exit

# import from libs/common.sh
source ../common/common.sh

# stop all running docker containers
# for each allowed_envs, stop the docker containers if running
for allowed_env in "${allowed_envs[@]}"
do
  # set image name replacing dots and slashes with underscores, in one line
  image_name=$(echo "dhis2_$allowed_env" | sed 's/[./]/_/g')
  # stop the docker container
  docker-compose -p "$image_name""_citus" down
done