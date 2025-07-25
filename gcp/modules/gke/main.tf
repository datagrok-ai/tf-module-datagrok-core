# File: gcp/modules/gke/main.tf
#
# Last modified: 2025/07/25 20:55:37

# GKE cluster

resource "google_container_cluster" "this" {
  name     = var.clusterName
  location = var.node_location

  enable_shielded_nodes    = "true"
  deletion_protection = false

  remove_default_node_pool = true
  initial_node_count       = 1

  networking_mode = "VPC_NATIVE"
  network    = var.network
  subnetwork = var.subnet

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "/16"
    services_ipv4_cidr_block = "/22"
  }

  private_cluster_config {
    enable_private_nodes = true
    enable_private_endpoint = false
    master_ipv4_cidr_block = "172.16.0.0/28"
  }

  master_authorized_networks_config {
    cidr_blocks {
        cidr_block   = "0.0.0.0/0"
        display_name = "Public Access"
      }
  }

  # disk_size_gb             = var.diskSize

  release_channel {
    channel = "STABLE"
  }

  # version = data.google_container_engine_versions.gke_version.release_channel_default_version["STABLE"]

  addons_config {
    http_load_balancing {
      disabled = false
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
      env = var.gcp_project,
      clasterName = var.clusterName
    }

    tags         = ["gke-node", var.clusterName]
    metadata = {
      disable-legacy-endpoints = "true"
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
}
