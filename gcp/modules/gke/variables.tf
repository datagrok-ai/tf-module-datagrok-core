variable "gcp_project" {
  description = "GCP project name"
  type        = string
  default     = null
}

variable "gcp_region" {
  description = "GCP region for all resources"
  type        = string
  default     = null
}

#

variable "k8s_version" {
  type        = string
  default     = null
  description = "-"
}

variable "network" {
  type        = string
  default     = null
  description = "-"
}

variable "subnet" {
  type        = string
  default     = null
  description = "-"
}

variable "node_location" {
  type        = string
  default     = null
  description = "-"
}


variable "clusterName" {
  description = "Name of our Cluster"
}
variable "diskSize" {
  description = "Node disk size in GB"
}
variable "minNode" {
  description = "Minimum Node Count"
}
variable "maxNode" {
  description = "maximum Node Count"
}
variable "machineType" {
  description = "Node Instance machine type"
}

variable "http_load_balancing" {
  type        = bool
  default     = false
  description = "-"
}
