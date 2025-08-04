resource "google_project" "project" {
  name                = "${var.app_name} ${upper(terraform.workspace)}"
  project_id          = "${lower(var.app_name)}-${terraform.workspace}-id"
  folder_id           = google_folder.project_folder.name
  auto_create_network = false
  tags = {
    environment = terraform.workspace
    reference   = "v1"
  }
}

resource "google_folder" "project_folder" {
  display_name = var.app_name
  parent       = var.parent_org_name
}