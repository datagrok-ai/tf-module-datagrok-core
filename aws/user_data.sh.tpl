#!/bin/bash
# shellcheck disable=SC2154
echo "ECS_CLUSTER=${ecs_cluster_name}" >>/etc/ecs/ecs.config
