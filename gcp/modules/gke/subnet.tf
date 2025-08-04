#
# workaround

# resource "google_compute_subnetwork" "pods_subnet" {
#   name          = "pods-subnet"
#   ip_cidr_range = "10.1.0.0/20"  # For GKE pods
#   region        = "<REGION>"     # e.g., us-central1
#   network       = google_compute_network.private_vpc.name
#   purpose       = "INTERNAL_HTTPS_LOAD_BALANCER"  # For GKE pod IPs
#   role          = "ACTIVE"
# }