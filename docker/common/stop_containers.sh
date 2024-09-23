#!/bin/bash

#saves current directory
current_dir=$(pwd)

#changes directory to the directory of the script
cd "$(dirname "$0")" || exit

# import from libs/common.sh
source ../common/common.sh

stop_all_containers