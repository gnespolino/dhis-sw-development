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

echo "Reset container for environment $env"

#removes slash from the env
docker_tag=$(normalize_docker_tag "$env")
db=$(normalize_db_name "$env")

reset_container "$env" "${DHIS2_DB_IMAGE_NAME}"-"$docker_tag" "$db"

cd "$current_dir" || exit