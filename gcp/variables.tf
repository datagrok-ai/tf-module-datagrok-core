variable "gcp_project" {
  description = "GCP project name"
  type        = string
  default     = null
}

variable "gcp_region" {
  description = "GCP region for all resources"
  type        = string
  default     = "europe-west3"
}

variable "node_location" {
  type        = string
  default     = null
  description = "-"
}

variable "cluster_name" {
  type        = string
  description = "gke cluster name, same name is used for vpc and subnets"
  default     = "kubernetes"
}

variable "cidrBlock" {
  type        = string
  description = "The cidr block for subnet"
  # default     = "10.1.0.0/16"
}

# variable "vpc_name" {
#   type        = string
#   description = "Name of the resource. Provided by the client when the resource is created. The name must be 1-63 characters long, and comply with RFC1035. Specifically, the name must be 1-63 characters long and match the regular expression [a-z]([-a-z0-9]*[a-z0-9])? which means the first character must be a lowercase letter, and all following characters must be a dash, lowercase letter, or digit, except the last character, which cannot be a dash."
# }

# variable "project_org_name" {
#   type    = string
#   default = "organizations/766620175410"
#   # description = "Application organization folder"
# }