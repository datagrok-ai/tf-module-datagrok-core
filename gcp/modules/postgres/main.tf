# File: gcp/modules/postgres/main.tf
# rev.0.0.2
#
# Last modified: 2025/07/27 16:11:50

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

  # tags = ["project", var.gcp_project]
}
