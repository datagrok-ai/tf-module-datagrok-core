# terraform {
#   backend "gcs" {
#     bucket = "terraform-webapp-state"
#     prefix = "terraform/webapp"
#   }
# }

terraform {
  required_version = ">= 1.12.2"
  backend "local" {
  }
}
