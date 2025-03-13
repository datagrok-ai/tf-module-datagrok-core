module "db_sg" {
  source  = "registry.terraform.io/terraform-aws-modules/security-group/aws"
  version = "~> 4.12.0"

  name        = "${local.rds_name}-db"
  description = "${local.rds_name} Datagrok DB Security Group"
  vpc_id      = try(module.vpc[0].vpc_id, var.vpc_id)

  # TODO: Egress disable
  egress_with_self = [
    {
      rule = "all-all"
    }
  ]
  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = try(module.vpc[0].vpc_cidr_block, var.cidr)
    },
  ]

  tags = local.tags
}
module "db" {
  source                         = "registry.terraform.io/terraform-aws-modules/rds/aws"
  version                        = "~> 5.0.3"
  identifier                     = local.rds_name
  instance_use_identifier_prefix = false
  db_name                        = var.db_name
  username                       = var.rds_master_username
  password                       = var.rds_master_password
  create_random_password         = try(length(var.rds_master_password) > 0, false) ? false : true
  port                           = "5432"
  engine                         = "postgres"
  engine_version                 = var.rds_major_engine_version
  major_engine_version           = var.rds_major_engine_version
  allow_major_version_upgrade    = false
  auto_minor_version_upgrade     = true
  family                         = "postgres${split(".", var.rds_major_engine_version)[0]}"
  instance_class                 = var.rds_instance_class
  allocated_storage              = var.rds_allocated_storage
  max_allocated_storage          = var.rds_max_allocated_storage
  publicly_accessible            = false
  storage_encrypted              = true
  storage_type                   = "gp2"
  kms_key_id                     = var.custom_kms_key ? try(module.kms[0].key_arn, var.kms_key) : null
  multi_az                       = var.rds_multi_az
  create_db_subnet_group         = false
  db_subnet_group_name           = try(module.vpc[0].database_subnet_group, var.database_subnet_group)
  vpc_security_group_ids         = [module.db_sg.security_group_id]

  iam_database_authentication_enabled   = true
  apply_immediately                     = false
  maintenance_window                    = "Mon:05:44-Mon:06:14"
  backup_window                         = "04:31-05:01"
  backup_retention_period               = var.rds_backup_retention_period
  delete_automated_backups              = true
  skip_final_snapshot                   = false
  final_snapshot_identifier_prefix      = "${local.rds_name}-final"
  deletion_protection                   = var.termination_protection
  performance_insights_enabled          = var.rds_performance_insights_enabled
  performance_insights_retention_period = 7
  create_monitoring_role                = var.rds_performance_insights_enabled
  monitoring_role_name                  = "${local.rds_name}-rds"
  monitoring_interval                   = "60"
  monitoring_role_use_name_prefix       = true
  monitoring_role_description           = "${local.rds_name} RDS monitoring role"
  enabled_cloudwatch_logs_exports       = ["postgresql"]

  create_db_parameter_group = true
  parameters = [
    {
      name  = "autovacuum"
      value = 1
    }
  ]

  tags = local.tags

}

resource "aws_route53_record" "db_private_dns" {
  count   = var.create_route53_internal_zone ? 1 : 0
  zone_id = aws_route53_zone.internal[0].zone_id
  name    = "db.${aws_route53_zone.internal[0].name}"
  type    = "CNAME"
  ttl     = 60
  #   records = [split(":", module.db.db_instance_endpoint)[0]]
  records = ["datagrok-public-17.cfxegszwqqvz.us-east-2.rds.amazonaws.com"]
}

data "aws_iam_policy" "backup_default_policy" {
  name = "AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role" "db_backup_role" {
  name = "${local.rds_backup_name}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "backup.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "db_attach_default_backup_policy" {
  role       = aws_iam_role.db_backup_role.name
  policy_arn = data.aws_iam_policy.backup_default_policy.arn
}

resource "aws_backup_vault" "db_backup_vault" {
  name        = "${local.rds_backup_name}-vault"
  kms_key_arn = local.create_kms ? module.kms[0].key_id : null
}
