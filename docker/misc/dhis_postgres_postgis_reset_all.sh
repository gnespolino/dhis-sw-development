#!/bin/bash

#saves current directory
current_dir=$(pwd)

#changes directory to the directory of the script
cd "$(dirname "$0")" || exit

source ../common/common.sh

for allowed_env in "${allowed_envs[@]}"; do
  echo "building docker image for $allowed_env"
  ./dhis_postgres_postgis_reset.sh "$allowed_env"
done