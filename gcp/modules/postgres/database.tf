# File: gcp/modules/postgres/database.tf
#

# Create a database
resource "google_sql_database" "this" {
  name            = var.db_name
  instance        = google_sql_database_instance.this.name
  deletion_policy = "ABANDON"
}

# Create a database user
resource "google_sql_user" "this" {
  name     = var.db_user
  instance = google_sql_database_instance.this.name
  password = var.db_password
}