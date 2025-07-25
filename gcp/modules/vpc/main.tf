# VPC and Subnets module

# VPC - https://registry.terraform.io/providers/hashicorp/google/6.6.0/docs/resources/compute_network
resource "google_compute_network" "this" {
  project = var.gcp_project_id
  name        = var.vpc_name
  description = var.vpc_description

  # the network is created in "custom subnet mode"
  # we will explicitly connect subnetwork resources below using google_compute_subnetwork resource
  auto_create_subnetworks = false
}

# Subnet - https://registry.terraform.io/providers/hashicorp/google/6.6.0/docs/resources/compute_subnetwork
resource "google_compute_subnetwork" "subnet1" {
  project = var.gcp_project_id
  name          = var.subnet_name
  description   = var.subnet_description
  region        = var.region
  network       = google_compute_network.this.name
  ip_cidr_range = var.cidrBlock
}