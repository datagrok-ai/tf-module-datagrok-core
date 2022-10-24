variable "name" {
  type     = string
  default  = "datagrok"
  nullable = false
}

variable "s3_name" {
  type     = string
  default  = null
  nullable = true
}

variable "environment" {
  type     = string
  default  = "public"
  nullable = false
}

variable "rds_master_username" {
  type     = string
  default  = "superuser"
  nullable = false
}

variable "rds_master_password" {
  type      = string
  default   = null
  sensitive = true
  nullable  = true
}

variable "rds_dg_password" {
  type      = string
  default   = null
  sensitive = true
  nullable  = true
}

variable "rds_instance_class" {
  type     = string
  default  = "db.t3.large"
  nullable = false
}

variable "rds_multi_az" {
  type     = bool
  default  = false
  nullable = true
}

variable "rds_allocated_storage" {
  type     = number
  default  = 50
  nullable = false
}

variable "rds_max_allocated_storage" {
  type     = number
  default  = 100
  nullable = false
}

variable "docker_hub_secret_arn" {
  type     = string
  default  = null
  nullable = true
}

variable "domain_name" {
  type     = string
  default  = null
  nullable = true
}

variable "acm_cert_arn" {
  type     = string
  default  = null
  nullable = true
}

variable "subject_alternative_names" {
  type     = list(string)
  default  = []
  nullable = false
}

variable "docker_datagrok_tag" {
  type     = string
  default  = "latest"
  nullable = false
}

variable "docker_grok_compute_tag" {
  type     = string
  default  = "latest"
  nullable = false
}

variable "docker_jkg_tag" {
  type     = string
  default  = "latest"
  nullable = false
}

variable "docker_jn_tag" {
  type     = string
  default  = "latest"
  nullable = false
}

variable "docker_h2o_tag" {
  type     = string
  default  = "latest"
  nullable = false
}

variable "admin_password" {
  type      = string
  sensitive = true
  default   = null
  nullable  = true
}
