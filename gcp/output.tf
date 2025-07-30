output "cluster_name" {
  value       = module.gke.cluster_name
  description = "GKE cluster name"
  sensitive   = false
}

output "instance_connection_name" {
  description = "Connection name of the Cloud SQL instance"
  value       = module.postgres.instance_connection_name
}

output "database_instance_ip" {
  description = "Public IP address of the Cloud SQL instance"
  value       = module.postgres.database_instance_ip
}

# output "database_name" {
#   description = "Name of the database"
#   value       = module.postgres.database_name
# }

# output "database_user" {
#   description = "Database user"
#   value       = module.postgres.database_user
#   sensitive   = false
# }

# output "database_password" {
#   description = "Database user password"
#   value       = nonsensitive(random_password.db_user.result)
#   sensitive   = false
# }

# output "database_admin_password" {
#   description = "Database admin password"
#   value       = nonsensitive(module.postgres.database_admin_password)
#   sensitive   = false
# }
