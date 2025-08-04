# VPC and Subnets module

# VPC - https://registry.terraform.io/providers/hashicorp/google/6.6.0/docs/resources/compute_network
resource "google_compute_network" "this" {
  project     = var.gcp_project_id
  name        = var.vpc_name
  description = var.vpc_description

  # the network is created in "custom subnet mode"
  # we will explicitly connect subnetwork resources below using google_compute_subnetwork resource
  auto_create_subnetworks = false
}

# Subnet - https://registry.terraform.io/providers/hashicorp/google/6.6.0/docs/resources/compute_subnetwork
resource "google_compute_subnetwork" "subnet1" {
  project       = var.gcp_project_id
  name          = var.subnet_name
  description   = var.subnet_description
  region        = var.region
  network       = google_compute_network.this.name
  ip_cidr_range = var.cidrBlock
}

# VPC
# resource "google_compute_network" "private_vpc" {
#   name                    = "my-private-vpc"
#   auto_create_subnetworks = false
# }

# # Subnet for GKE nodes
# resource "google_compute_subnetwork" "gke_subnet" {
#   name          = "gke-subnet"
#   ip_cidr_range = "10.0.0.0/24"  # For GKE nodes
#   region        = "<REGION>"     # e.g., us-central1
#   network       = google_compute_network.private_vpc.name
#   private_ip_google_access = true  # Enable Private Google Access
# }

# Subnet for GKE pods


# Subnet for GKE services
# resource "google_compute_subnetwork" "services_subnet" {
#   name          = "services-subnet"
#   ip_cidr_range = "10.2.0.0/24"  # For GKE services
#   region        = "<REGION>"     # e.g., us-central1
#   network       = google_compute_network.private_vpc.name
#   purpose       = "INTERNAL_HTTPS_LOAD_BALANCER"  # For GKE service IPs
#   role          = "ACTIVE"
# }

# # Subnet for Cloud SQL
# resource "google_compute_subnetwork" "sql_subnet" {
#   name          = "sql-subnet"
#   ip_cidr_range = "10.3.0.0/24"  # For Cloud SQL private IP
#   region        = "<REGION>"     # e.g., us-central1
#   network       = google_compute_network.private_vpc.name
#   private_ip_google_access = true  # Enable Private Google Access
# }