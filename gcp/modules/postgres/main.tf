# File: gcp/modules/postgres/main.tf
#

resource "google_sql_database_instance" "this" {
  name             = var.server_name
  database_version = "POSTGRES_17"
  region           = var.region

  settings {
    tier = "db-f1-micro"

    backup_configuration {
      enabled = true
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.vpc_id
    }
  }
}
