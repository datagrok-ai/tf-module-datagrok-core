output "vpc_self_link" {
  description = "The URI of the created resource"
  value       = google_compute_network.this.self_link
}

output "subnet_self_link" {
  description = "The URI of the created resource"
  value       = google_compute_subnetwork.subnet1.self_link
}

output "network" {
  description = "vpc network name"
  value       = google_compute_network.this.name
}

output "network_id" {
  description = "vpc network id"
  value       = google_compute_network.this.id
}

output "subnet1" {
  description = "subnet name"
  value       = google_compute_subnetwork.subnet1.name
}
