#!/bin/bash

set -e

function help() {
  echo
  echo "Usage: ./ecr_push.sh [--help] [--image <Docker Hub Image>] [--ecr <ECR Repository URL>] [--tag <Tag for Image>]"
  echo
  echo "Script to push image from Docker Hub to ECR Repository."
  echo
  echo "Options:"
  echo "--help    Show this help message and exit"
  echo "--image   Image in Docker Hub, for example, datagrok/datagrok"
  echo "--ecr     ECR Repository URL, for example, 123456789.dkr.ecr.us-east-1.amazonaws.com/datagrok"
  echo "--tag     Image tag to publish from Docker Hub to ECR repository, for example, latest"
}

while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        --image)
        image=$2
        shift
        ;;
        --ecr)
        ecr=$2
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


if [ -z "${image}" ] || [ -z "${ecr}" ]
then
  echo 'You need to specify both Docker Hub image and ECR repository URL'
  help
  exit 1
fi

region="$(echo "${ecr}" | awk -F'.' '{print $4}')"

aws ecr get-login-password --region "${region}" | docker login --username AWS --password-stdin "${ecr}"
docker pull "${image}:${tag}"
docker tag "${image}:${tag}" "${ecr}:${tag}"
docker push "${ecr}:${tag}"
