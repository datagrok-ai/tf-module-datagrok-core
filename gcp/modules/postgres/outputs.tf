# Output connection details
output "instance_connection_name" {
  description = "Connection name of the Cloud SQL instance"
  value       = google_sql_database_instance.this.connection_name
}

output "database_instance_ip" {
  description = "Public IP address of the Cloud SQL instance"
  value       = google_sql_database_instance.this.public_ip_address
}

output "database_name" {
  description = "Name of the database"
  value       = google_sql_database.this.name
}

output "database_user" {
  description = "Database user"
  value       = google_sql_user.this.name
  sensitive   = true
}