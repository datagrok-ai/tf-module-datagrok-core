module "datagrok" {
  # We recommend to specify an exact tag as ref argument
  source                      = "git@github.com:datagrok-ai/tf-module-datagrok-core.git//aws?ref=main"
  name                        = var.name
  environment                 = var.environment
  admin_password              = var.admin_password
  cidr                        = "10.0.0.0/17"
  rds_major_engine_version    = "11"
  rds_master_username         = var.rds_master_username
  rds_master_password         = var.rds_master_password
  rds_dg_password             = var.rds_dg_password
  rds_instance_class          = var.rds_instance_class
  rds_multi_az                = var.rds_multi_az
  rds_allocated_storage       = var.rds_allocated_storage
  rds_max_allocated_storage   = var.rds_max_allocated_storage
  rds_backup_retention_period = 7
  ecs_launch_type             = "EC2"
  docker_hub_secret_arn       = var.docker_hub_secret_arn
  route53_enabled             = false
  #  domain_name                               = var.domain_name
  #  subject_alternative_names                 = var.subject_alternative_names
  acm_cert_arn                = var.acm_cert_arn
  termination_protection      = false
  key_pair_name               = "grok"
  set_admin_password          = false

  docker_datagrok_tag = var.docker_datagrok_tag

  ecs_cluster_insights             = true
  ec2_detailed_monitoring_enabled  = true
  rds_performance_insights_enabled = true

  enable_flow_logs      = true
  enable_bucket_logging = true

  monitoring_email_alerts_datagrok = false
  monitoring_email_recipients      = ["spodolskaya@datagrok.ai"]
}
