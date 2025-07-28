# File: gcp/bucket.tf
# rev.0.0.1
#
# Last modified: 2025/07/27 20:49:16

# Variables for sensitive data
# variable "gcp_service_account_key" {
#   description = "GCP service account key JSON"
#   type        = string
#   sensitive   = true
# }

# Variables
variable "bucket_name_prefix" {
  description = "Name of the GCS bucket"
  type        = string
  default     = "datagrok-bucket-test"
}

# Create a service account
resource "google_service_account" "app" {
  account_id   = "datagrok-storage-admin-sa"
  display_name = "Service Account with Storage Admin"
  project      = var.gcp_project
}

# Generate a JSON key for the service account
resource "google_service_account_key" "app" {
  service_account_id = google_service_account.app.name
}

# Create a Google Cloud Storage bucket
resource "google_storage_bucket" "datagrok_data" {
  name = join("-",
    [
      var.bucket_name_prefix,
      random_string.index.result
    ]
  )

  location      = var.gcp_region
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  # Lifecycle rule for cost-effectiveness
  lifecycle_rule {
    condition {
      age = 30 # Move objects to NEARLINE after 30 days
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  versioning {
    enabled = false
  }
}

# # Grant Cloud SQL Admin role
# resource "google_project_iam_member" "sql_admin" {
#   project = jsondecode(file("config.json")).project_id
#   role    = "roles/cloudsql.admin"
#   member  = "serviceAccount:${google_service_account.app.email}"
# }

# Grant Storage Admin role
resource "google_project_iam_member" "storage_admin" {
  project = var.gcp_project
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.app.email}"
}

# Output bucket details
output "bucket_name" {
  description = "Name of the GCS bucket"
  value       = google_storage_bucket.datagrok_data.name
}

output "bucket_url" {
  description = "URL of the GCS bucket"
  value       = google_storage_bucket.datagrok_data.url
}

output "service_account_credentials_json" {
  description = "JSON credentials for the service account"
  value       = base64decode(google_service_account_key.app.private_key)
  sensitive   = true
}

# debug
# output "service_account_credentials_json" {
#   description = "JSON credentials for the service account"
#   value       = nonsensitive(base64decode(google_service_account_key.app.private_key))
#   sensitive   = false
# }
