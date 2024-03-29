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

while [[ $# -gt 0 ]]; do
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

if [ -z "${image}" ] || [ -z "${ecr}" ]; then
  echo 'You need to specify both Docker Hub image and ECR repository URL'
  help
  exit 1
fi

source_tag=$tag
if [[ $tag == "latest-"* ]]; then
  source_tag="latest"
fi
if [[ $tag == "bleeding-edge-"* ]]; then
  source_tag="bleeding-edge"
fi

region="$(echo "${ecr}" | awk -F'.' '{print $4}')"
ecr_url="$(echo "${ecr}" | awk -F'/' '{print $1}')"
ecr_repo_name="$(echo "${ecr}" | awk -F'/' '{print $2}')"

if [ -n "$(jq ".auths | select(has(\"${ecr_url}\") == true)" "${HOME}/.docker/config.json")" ]; then
  echo "Already logged in to ECR Repository: ${ecr_url}"
else
  echo "Login to ECR Repository: ${ecr_url}"
  aws ecr get-login-password --region "${region}" | docker login --username AWS --password-stdin "${ecr_url}"
fi

echo "Pull image from Docker Hub: ${image}:${source_tag}"
docker pull "${image}:${source_tag}"
echo "Copy image from Docker Hub ${image}:${source_tag} to ECR ${ecr}:${tag}"
docker tag "${image}:${source_tag}" "${ecr}:${tag}"

echo "Push image to ECR ${ecr}:${tag}"
docker_push=$(docker push "${ecr}:${tag}" 2>&1 || true)
echo "${docker_push}"
if [[ $docker_push == *"no basic auth credentials"* ]] || [[ $docker_push == *"denied: Your authorization token has expired. Reauthenticate and try again"* ]] ; then
  echo "Re-login to ECR Repository: ${ecr_url}"
  aws ecr get-login-password --region "${region}" | docker login --username AWS --password-stdin "${ecr_url}"
  echo "Push image to ECR ${ecr}:${tag} after login to ECR Repository"
  docker push "${ecr}:${tag}"
elif [[ $docker_push == *"tag invalid: The image tag '${tag}' already exists in the '${ecr_repo_name}' repository and cannot be overwritten because the repository is immutable"* ]]; then
  echo "Push to ECR repository FAILED: ${ecr}:${tag} already exists in the immutable repository"
  exit 1
else
  echo "Docker image ${image}:${source_tag} was pushed to ECR ${ecr}:${tag}"
fi
