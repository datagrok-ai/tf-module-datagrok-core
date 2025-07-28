output "gcp_project_name" {
  value       = google_project.project.name
  sensitive   = false
  description = "GCP project name"
  depends_on  = []
}

output "gcp_project_id" {
  value       = google_project.project.id
  sensitive   = false
  description = "GCP project ID"
  depends_on  = []
}