#!/bin/bash

set -e

function help() {
  echo
  echo "Usage: ./docker_hash.sh [--help] [--image <Docker Hub Image>] [--tag <Tag for Image>]"
  echo
  echo "Script to check image hashsum."
  echo
  echo "Options:"
  echo "--help    Show this help message and exit"
  echo "--image   Image, for example, datagrok/datagrok"
  echo "--tag     Image tag to check, for example, latest"
}

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
  --image)
    image=$2
    shift
    ;;
  --tag)
    tag=${2:-latest}
    shift
    ;;
  *)
    echo "option \'$1\' is not understood!"
    help
    exit -1
    break
    ;;
  esac
  shift
done

if [ -z "${image}" ] || [ -z "${tag}" ]; then
  echo 'You need to specify Docker Image'
  help
  exit 1
fi

docker pull "${image}:${tag}"
docker inspect --format='{{index .RepoDigests 0}}' "${image}:${tag}"
