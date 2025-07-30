# File: gcp/modules/postgres/services.tf
#

resource "google_project_service" "servicenetworking" {
  project = var.gcp_project

  service = "servicenetworking.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "sqladmin" {
  project = var.gcp_project
  service = "sqladmin.googleapis.com"

  disable_on_destroy = false
}
