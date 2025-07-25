# File: main.tf
# rev: v0.1.1
#
# Last modified: 2025/07/25 21:00:16

resource "random_string" "suffix" {
  length  = 5
  upper   = true
  lower   = true
  numeric = true
  special = false

  # keepers = {
  #   id = value
  # }
}

# 2ref: workaround

locals {
  # full_cluster_name = join("-",
  #   [
  #     terraform.workspace,
  #     var.cluster_name,
  #     random_string.suffix.result
  #   ]
  # )
  full_cluster_name = var.cluster_name
}

data "google_container_engine_versions" "gke_version" {
  location       = var.gcp_region
  version_prefix = "1.31."
}

#
# VPC
module "vpc" {
  # invoke vpc_and_subnets module under modules directory
  source = "./modules/vpc"

  # count = 0

  gcp_project_id = var.gcp_project

  # create vpc and subnet with the same name as cluster name
  vpc_name    = "vpc-${local.full_cluster_name}"
  subnet_name = "subnet-${local.full_cluster_name}"

  # region where the resources need to be created
  region = var.gcp_region

  cidrBlock = var.cidrBlock
}

locals {
  machineType     = "n2-standard-2"
  mashineDiskSize = 30
  clusterMaxNodes = 3
  # clusterName     = "gke-test-1"

}

#
# Postgres
module "postgres" {
  source = "./modules/postgres"
  # gcp_project   = var.gcp_project
  region = var.gcp_region

  server_name = "datagrog-postgres"
  vpc_id      = module.vpc.network_id

}

#
# GKE
module "gke" {
  source        = "./modules/gke"
  gcp_project   = var.gcp_project
  gcp_region    = var.gcp_region
  node_location = var.node_location

  clusterName = local.full_cluster_name
  diskSize    = local.mashineDiskSize
  minNode     = 1
  maxNode     = local.clusterMaxNodes
  machineType = local.machineType

  network = module.vpc.network
  subnet  = module.vpc.subnet1
}