locals {
  tags = merge(var.tags, {
    Service     = "Datagrok"
    FullName    = "${var.name}-${var.environment}"
    Environment = var.environment
    Terraform   = "true"
  })
  full_name       = "${var.name}-${var.environment}"
  vpc_name        = coalesce(var.vpc_name, "${var.name}-${var.environment}")
  rds_name        = coalesce(var.rds_name, "${var.name}-${var.environment}")
  rabbitmq_name   = coalesce(var.rabbitmq_name, "${var.name}-${var.environment}")
  s3_name         = coalesce(var.s3_name, "${var.name}-${var.environment}")
  ecs_name        = coalesce(var.ecs_name, "${var.name}-${var.environment}")
  lb_name         = coalesce(var.lb_name, "${var.name}-${var.environment}")
  ec2_name        = coalesce(var.ec2_name, "${var.name}-${var.environment}")
  sns_topic_name  = coalesce(var.sns_topic_name, "${var.name}-${var.environment}")
  rds_backup_name = coalesce(var.rds_backup_name, "${var.name}-${var.environment}-rds-backup")

  r53_record = var.route53_enabled ? try("${var.route53_record_name}.${var.domain_name}", "${var.name}-${var.environment}.${var.domain_name}") : ""
  create_kms = var.custom_kms_key && !try(length(var.kms_key) > 0, false)
  images = {
    datagrok = {
      image = var.docker_datagrok_image
      tag   = var.docker_datagrok_tag == "latest" || var.docker_datagrok_tag == "bleeding-edge" ? "${var.docker_datagrok_tag}-${formatdate("YYYYMMDDhhmmss", timestamp())}" : var.docker_datagrok_tag
    },
    grok_connect = {
      image = var.docker_grok_connect_image
      tag   = var.docker_grok_connect_tag == "latest" || var.docker_grok_connect_tag == "bleeding-edge" ? "${var.docker_grok_connect_tag}-${formatdate("YYYYMMDDhhmmss", timestamp())}" : var.docker_grok_connect_tag
    },
    grok_spawner = {
      image = var.docker_grok_spawner_image
      tag   = var.docker_grok_spawner_tag == "latest" || var.docker_grok_spawner_tag == "bleeding-edge" ? "${var.docker_grok_spawner_tag}-${formatdate("YYYYMMDDhhmmss", timestamp())}" : var.docker_grok_spawner_tag
    },
    "ecs-searchdomain-sidecar-${var.name}-${var.environment}" = {
      image = "docker/ecs-searchdomain-sidecar"
      tag   = "1.0"
    }
    "smtp-${var.name}-${var.environment}" = {
      image = "bytemark/smtp"
      tag   = "stretch"
    },
    "kaniko-${var.name}-${var.environment}" = {
      image = "gcr.io/kaniko-project/executor"
      tag   = "v1.9.2"
    }
  }

  targets = [
    {
      name             = "dg"
      backend_protocol = "HTTP"
      backend_port     = 8080
      target_type      = aws_ecs_task_definition.datagrok.network_mode == "awsvpc" ? "ip" : "instance"
      health_check = {
        enabled             = true
        interval            = 300
        unhealthy_threshold = 10
        path                = "/api/admin/health"
        matcher             = "200"
      }
    },
    {
      name             = "connect"
      backend_protocol = "HTTP"
      backend_port     = 1234
      target_type      = aws_ecs_task_definition.grok_connect.network_mode == "awsvpc" ? "ip" : "instance"
      health_check = {
        enabled             = true
        interval            = 60
        unhealthy_threshold = 5
        path                = "/health"
        matcher             = "200"
      }
    },
    {
      name             = "spawner"
      backend_protocol = "HTTP"
      backend_port     = 8000
      target_type      = aws_ecs_task_definition.grok_spawner.network_mode == "awsvpc" ? "ip" : "instance"
      health_check = {
        enabled             = true
        interval            = 60
        unhealthy_threshold = 5
        path                = "/info"
        matcher             = "200"
      }
    },
    {
      name             = "pipe"
      backend_protocol = "HTTP"
      backend_port     = 3000
      target_type      = aws_ecs_task_definition.grok_pipe.network_mode == "awsvpc" ? "ip" : "instance"
      health_check = {
        healthy_threshold = 5
        enabled             = true
        interval            = 30
        unhealthy_threshold = 2
        path                = "/info"
        matcher             = "200"
      }
    }
  ]
}

data "aws_availability_zones" "available" {
  state = "available"
}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
module "kms" {
  count   = local.create_kms ? 1 : 0
  source  = "registry.terraform.io/terraform-aws-modules/kms/aws"
  version = "~> 1.1.0"

  aliases                 = [local.full_name]
  description             = "Datagrok KMS for ${local.full_name}"
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  is_enabled              = true
  create_external         = false
  multi_region            = false

  # Policy
  enable_default_policy = true
  key_owners = try(length(var.kms_owners) > 0, false) ? var.kms_owners : [
    data.aws_caller_identity.current.arn
  ]
  key_administrators = try(length(var.kms_admins) > 0, false) ? var.kms_admins : [
    data.aws_caller_identity.current.arn
  ]
  key_users = try(length(var.kms_users) > 0, false) ? var.kms_users : [data.aws_caller_identity.current.arn]
  #  key_service_users     = [
  #    aws_iam_role.task.arn,
  #    aws_iam_role.exec.arn,
  #    aws_iam_role.datagrok_service.arn,
  #    aws_iam_instance_profile.datagrok_profile[0].arn
  #  ]

  tags = local.tags
}
