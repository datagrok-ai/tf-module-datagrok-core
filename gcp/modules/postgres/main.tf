# File: gcp/modules/postgres/main.tf
# rev.0.1.1
#
# Last modified: 2025/07/28 17:33:55

# Subnet for Cloud SQL
resource "google_compute_subnetwork" "sql_subnet" {
  name                     = "sql-subnet"
  ip_cidr_range            = var.ip_cidr_range
  region                   = var.region
  network                  = var.vpc_id
  private_ip_google_access = true # Enable Private Google Access
}

# VPC Peering 
# resource "google_compute_network_peering" "sql-subnet" {
#   name                     = "peering-sql-to-vpc"
#   network                  = var.vpc_id
#   peer_network             = 
#   # Optional: Export/import custom routes if needed
#   export_custom_routes     = true
#   import_custom_routes     = true
# }

# resource "google_service_networking_connection" "private_vpc_connection" {
#   network                 = "projects/${var.gcp_project}/global/networks/${var.vpc_id}"
#   service                 = "servicenetworking.googleapis.com"
#   reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
# }

# resource "google_compute_global_address" "private_ip_range" {
#   name          = "sql-private-ip-range"
#   purpose       = "VPC_PEERING"
#   address_type  = "INTERNAL"
#   prefix_length = 16
#   network       = "projects/${var.gcp_project}/global/networks/${var.vpc_id}"
# }

resource "google_sql_database_instance" "this" {
  name             = var.server_name
  database_version = "POSTGRES_17"
  region           = var.region

  settings {
    tier    = "db-custom-1-3840"
    edition = "ENTERPRISE"
    ip_configuration {
      ipv4_enabled = true
      # private_network = var.vpc_id
      authorized_networks {
        name  = "allow-all"
        value = "0.0.0.0/0" # Warning: Open to all IPs for simplicity; restrict in production
      }
    }
  }

  deletion_protection = false
  # depends_on = [google_service_networking_connection.private_vpc_connection]

  # tags = ["project", var.gcp_project]
}