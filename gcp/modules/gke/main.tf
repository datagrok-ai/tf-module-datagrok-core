# File: gcp/modules/gke/main.tf
# rev.0.1.1
#
# Last modified: 2025/07/28 17:29:18

# GKE cluster

# 2ref: workaround till develop
resource "google_compute_subnetwork" "subnet" {
  name          = "gke-public-subnet"
  ip_cidr_range = "10.20.0.0/16"
  region        = var.gcp_region
  network       = var.network
}

resource "google_container_cluster" "this" {
  name     = var.clusterName
  location = var.node_location

  enable_shielded_nodes = "true"
  deletion_protection   = false

  remove_default_node_pool = true
  initial_node_count       = 1

  # Specify the Kubernetes version for the control plane
  min_master_version = var.k8s_version

  network    = var.network
  subnetwork = google_compute_subnetwork.subnet.name

  ip_allocation_policy {}

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0"
      display_name = "Public Access"
    }
  }

  release_channel {
    channel = "STABLE"
  }

  addons_config {
    http_load_balancing {
      disabled = var.http_load_balancing
    }
  }

  timeouts {
    create = "20m"
    update = "20m"
  }

  lifecycle {
    ignore_changes = [node_pool]
  }

  # tags = {
  #   "${local.project_project_name}/environment" = terraform.workspace
  #   "${local.project_project_name}/reference"   = "v1"
  # }
}

resource "google_container_node_pool" "this" {
  name       = "${var.clusterName}-pool"
  location   = var.node_location
  cluster    = google_container_cluster.this.name
  node_count = 1

  version = var.k8s_version

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  autoscaling {
    min_node_count = var.minNode
    max_node_count = var.maxNode
  }

  timeouts {
    create = "20m"
    update = "20m"
  }

  node_config {
    preemptible  = true
    machine_type = var.machineType

    labels = {
      env         = var.gcp_project,
      clasterName = var.clusterName
    }

    tags = ["gke-node", var.clusterName]
    metadata = {
      disable-legacy-endpoints = "true"
      block-project-ssh-keys   = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring"
    ]

    # oauth_scopes = [
    #   "https://www.googleapis.com/auth/compute",
    #   "https://www.googleapis.com/auth/cloud-platform",
    #   "https://www.googleapis.com/auth/devstorage.read_only",
    #   "https://www.googleapis.com/auth/logging.write",
    #   "https://www.googleapis.com/auth/monitoring",
    # ]
  }

  lifecycle {
    ignore_changes = [
      node_count,
      autoscaling,
      node_config[0].machine_type
    ]
  }

}
