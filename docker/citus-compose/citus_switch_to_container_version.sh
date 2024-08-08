#!/bin/bash

#saves current directory
current_dir=$(pwd)

#changes directory to the directory of the script
cd "$(dirname "$0")" || exit

./citus_start-docker.sh false

#changes directory back to the original directory
cd "$current_dir"