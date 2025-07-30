# File: main.tf
# rev: v0.1.5
#
# Last modified: 2025/07/30 15:43:47

resource "random_string" "index" {
  length  = 5
  upper   = false
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

#
# VPC
module "vpc" {
  source         = "./modules/vpc"
  gcp_project_id = var.gcp_project

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
  gcpSunbet       = "10.20.0.0/16"
}

#
# Postgres

resource "random_password" "db_user" {
  length  = 32
  upper   = true
  lower   = true
  numeric = true
  special = true

  # keepers = {
  #   id = value
  # }
}


resource "google_project_service" "cloudsql_admin_api" {
  project            = var.gcp_project
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = true
}

module "postgres" {
  source      = "./modules/postgres"
  gcp_project = var.gcp_project
  region      = var.gcp_region

  server_name   = "datagrog-postgres"
  vpc_id        = module.vpc.network_id
  ip_cidr_range = var.cidrSQL

  db_name     = "datagrok"
  db_user     = "datagrok"
  db_password = random_password.db_user.result

}

#
# GKE

data "google_container_engine_versions" "gke_version" {
  location       = var.gcp_region
  version_prefix = "1.31."
}

# Enable GKE API
resource "google_project_service" "container" {
  project = var.gcp_project
  service = "container.googleapis.com"
}

module "gke" {
  source        = "./modules/gke"
  gcp_project   = var.gcp_project
  gcp_region    = var.gcp_region
  node_location = var.node_location

  k8s_version = "1.33.2-gke.4655000"

  http_load_balancing = true ? false : true

  clusterName = local.full_cluster_name
  diskSize    = local.mashineDiskSize
  minNode     = 1
  maxNode     = local.clusterMaxNodes
  machineType = local.machineType

  network = module.vpc.network
  subnet  = module.vpc.subnet1
}