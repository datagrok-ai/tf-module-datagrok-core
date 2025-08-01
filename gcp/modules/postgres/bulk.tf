

# # Grant the service account Cloud SQL Admin role
# resource "google_project_iam_member" "sql_admin" {
#   project = jsondecode(file("config.json")).project_id
#   role    = "roles/cloudsql.admin"
#   member  = "serviceAccount:${jsondecode(var.gcp_service_account_key).client_email}"
# }

