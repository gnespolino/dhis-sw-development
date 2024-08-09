#!/bin/bash

declare -a allowed_envs=("dev" "2.39" "2.40" "2.41" "2.39.0/analytics_be" "2.39.0.1/analytics_be")

export allowed_envs

export DHIS2_DB_IMAGE_NAME="dhis2-db-sl"

#defines a function to send notifications
send_notification() {
  if [ -x "$(command -v notify-send)" ]; then
    notify-send "$1" "$2"
  fi
}

#defines a function to send export env vars
choose_env() {
  # concatenate envs with a pipe

  envs=$(printf "%s|" "${allowed_envs[@]}")

  env=$(zenity --forms --title="Database install tool" \
      --text="Choose DB Version to use" \
      --add-combo="Database version" --combo-values="$envs")

  echo "$env"
}

check_env() {
  env=$1
  if [[ ! " ${allowed_envs[@]} " =~ " ${env} " ]]; then
    zenity --error --text="Invalid environment. Use one of the following:\n $envs"
    exit 1
  fi

  #if user presses cancel or esc button, exit
  if [ -z "$env" ]
  then
    echo "User cancelled"
    exit 1
  fi
}

normalize_db_name() {
  db=$(echo "dhis2_$1" | sed 's/[./]/_/g')
  echo "$db"
}

normalize_docker_tag() {
  docker_tag=$(echo $1 | sed 's/[/]/-/g')
  echo "$docker_tag"
}

ask_repopulate() {
  if (zenity --question --text="Do you want to repopulate the database?"); then
    repopulate=true
  else
    repopulate=false
  fi
  echo "$repopulate"
}

build_docker_image() {
  env=$1
  image_name=$2
  docker_tag=$(normalize_docker_tag $env)

  # builds dhis postgres-postgis image for specified version if it doesn't exist
  if ! docker images | grep -q "${image_name}" | grep -q "$docker_tag" ; then
      #if env is dev tag the image also with latest
      docker build -t "${image_name}":"$docker_tag" --build-arg="DHIS2_VERSION=$env" .
      if [ "$env" == "dev" ]; then
        docker tag "${image_name}":"$docker_tag" "${image_name}":latest
      fi
  fi
}

reset_container() {
  env=$1
  container_name=$2
  volume_name=$3

  # delete the image if it exists
  echo "deleting container ${container_name}"

  # stops any instances of the container
  docker ps -a

  containers=$(docker ps -a | grep "${container_name}" | awk '{print $1}')
  for container in $containers; do
    echo "stopping container $container"
    docker stop "$container" --signal KILL || true
    echo "removing container $container"
    docker rm "$container" --force || true
  done

  # removes the volume
  echo "deleting volume ${volume_name}"
  docker volume rm "${volume_name}" --force || true

  echo "Volumes after deletion"
  docker volume ls
}

stop_all_containers() {
  for allowed_env in "${allowed_envs[@]}"
  do
    # set image name replacing dots and slashes with underscores, in one line
    docker_tag=$(echo $allowed_env | sed 's/[/]/-/g')
    container_name=${DHIS2_DB_IMAGE_NAME}-"$docker_tag"
    # stop the docker container
    docker stop "$container_name"
  done
}