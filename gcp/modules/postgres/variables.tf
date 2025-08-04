variable "region" {
  type        = string
  default     = null
  description = "-"
}

variable "vpc_id" {
  type        = string
  default     = null
  description = "-"
}
variable "ip_cidr_range" {
  type        = string
  default     = null
  description = "-"
}

variable "server_name" {
  type        = string
  default     = "postgres-server"
  description = "-"
}

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

variable "db_instance_name" {
  description = "Name of the Cloud SQL instance"
  type        = string
  default     = "postgres-instance"
}

variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = null
}

variable "db_user" {
  description = "PostgreSQL database user"
  type        = string
  default     = null
}

variable "db_password" {
  description = "PostgreSQL database user password"
  type        = string
  sensitive   = true
  default     = "securepassword123" # Replace with a secure password or use a secret
}