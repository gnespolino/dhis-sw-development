#!/bin/bash -x

#saves current directory
current_dir=$(pwd)

#changes directory to the directory of the script
cd "$(dirname "$0")" || exit

# import common
source ../common/common.sh

for allowed_env in "${allowed_envs[@]}"; do
  echo "Rebuilding database for $allowed_env"
  ./citus_start-docker.sh true $allowed_env
done

echo "All databases rebuilt"

# restore the original directory
cd "$current_dir" || exit