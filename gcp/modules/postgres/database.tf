# File: gcp/modules/postgres/database.tf
#

# Create a database
# resource "google_sql_database" "this" {
#   name            = var.db_name
#   instance        = google_sql_database_instance.this.name
#   deletion_policy = "ABANDON"
# }

# Create a database user
# resource "google_sql_user" "this" {
#   name     = var.db_user
#   instance = google_sql_database_instance.this.name
#   password = var.db_password
# }

resource "random_password" "admin" {
  length  = 32
  upper   = true
  lower   = true
  numeric = true
  special = true
}

resource "google_sql_user" "admin" {
  name     = "postgres"
  instance = google_sql_database_instance.this.name
  password = random_password.admin.result
}