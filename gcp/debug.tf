# File: debug.tf
#

data "google_client_openid_userinfo" "provider_identity" {
}

data "google_client_config" "provider" {
}

output "debug_provider_identity" {
  value     = data.google_client_openid_userinfo.provider_identity
  sensitive = false
}

# output "debug_provider" {
#   value       = data.google_client_config.provider
#   sensitive   = true
#   description = "-"
# }
