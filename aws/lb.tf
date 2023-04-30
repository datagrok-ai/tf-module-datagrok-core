resource "random_string" "lb_id" {
  for_each = {
    for target in local.targets :
    target.name => target
  }
  length  = 2
  special = false
  keepers = { target_type = each.value["target_type"] }
}

module "lb_ext_sg" {
  source  = "registry.terraform.io/terraform-aws-modules/security-group/aws"
  version = "~> 4.12.0"

  name        = "${local.lb_name}-lb-ext"
  description = "${local.lb_name}-lb-ext Datagrok LB Security Group"
  vpc_id      = try(module.vpc[0].vpc_id, var.vpc_id)

  egress_with_source_security_group_id = [
    {
      from_port                = 0
      to_port                  = 65535
      protocol                 = "tcp"
      description              = "Datagrok egress rules from LB to ECS"
      source_security_group_id = module.sg.security_group_id
    },
  ]

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "Access to HTTP"
      cidr_blocks = var.lb_access_cidr_blocks
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Access to HTTPS"
      cidr_blocks = var.lb_access_cidr_blocks
    },
  ]
}
module "lb_int_sg" {
  source  = "registry.terraform.io/terraform-aws-modules/security-group/aws"
  version = "~> 4.12.0"

  name        = "${local.lb_name}-lb-int"
  description = "${local.lb_name}-int Datagrok LB Security Group"
  vpc_id      = try(module.vpc[0].vpc_id, var.vpc_id)

  egress_with_source_security_group_id = [
    {
      from_port                = 0
      to_port                  = 65535
      protocol                 = "tcp"
      description              = "Egress rules from LB to ECS"
      source_security_group_id = module.sg.security_group_id
    },
  ]

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "Access to Datagrok"
      cidr_blocks = try(module.vpc[0].vpc_cidr_block, var.cidr)
    },
    {
      from_port   = 1234
      to_port     = 1234
      protocol    = "tcp"
      description = "Access to Grok Connect"
      cidr_blocks = try(module.vpc[0].vpc_cidr_block, var.cidr)
    },
    {
      from_port   = 8000
      to_port     = 8000
      protocol    = "tcp"
      description = "Access to Grok Spawner"
      cidr_blocks = try(module.vpc[0].vpc_cidr_block, var.cidr)
    },
  ]
}
data "aws_route53_zone" "external" {
  count        = !var.create_route53_external_zone && var.route53_enabled ? 1 : 0
  name         = var.domain_name
  private_zone = false
}
resource "aws_route53_zone" "external" {
  count = var.create_route53_external_zone && var.route53_enabled ? 1 : 0
  name  = var.domain_name
  tags  = local.tags
}
module "acm" {
  source  = "registry.terraform.io/terraform-aws-modules/acm/aws"
  version = "~> 3.5.0"
  count   = var.acm_cert_create ? 1 : 0

  domain_name       = var.domain_name
  zone_id           = var.route53_enabled && var.create_route53_external_zone ? aws_route53_zone.external[0].zone_id : data.aws_route53_zone.external[0].zone_id
  validation_method = "DNS"

  subject_alternative_names = var.subject_alternative_names

  create_route53_records = var.route53_enabled
  validate_certificate   = true
  wait_for_validation    = true
  validation_record_fqdns = var.route53_enabled ? [] : distinct(
    [
      for domain in compact(concat(
        [
          var.domain_name
        ],
      var.subject_alternative_names)) : "_f36e88adbd7b4c92a11a58ffc7f6808e.${replace(domain, "*.", "")}"
    ]
  )

  tags = local.tags
}
module "lb_ext" {
  source  = "registry.terraform.io/terraform-aws-modules/alb/aws"
  version = "~> 6.10.0"

  name                       = "${local.lb_name}-ext"
  load_balancer_type         = "application"
  vpc_id                     = try(module.vpc[0].vpc_id, var.vpc_id)
  subnets                    = try(module.vpc[0].public_subnets, var.public_subnet_ids)
  security_groups            = [module.lb_ext_sg.security_group_id]
  drop_invalid_header_fields = true

  idle_timeout = 300

  access_logs = var.bucket_logging.enabled ? {
    bucket  = var.bucket_logging.create_log_bucket ? module.log_bucket.s3_bucket_id : var.bucket_logging.log_bucket
    prefix  = "lb"
    enabled = true
  } : { bucket = "", enabled = false }

  target_groups = [for target in local.targets : merge(target, { name = "${local.lb_name}-ext-${target["name"]}${random_string.lb_id[target["name"]].result}" })]

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = try(module.acm[0].acm_certificate_arn, var.acm_cert_arn)
      target_group_index = 0
    }
  ]

  http_tcp_listeners = [
    {
      action_type = "redirect"
      port        = 80
      protocol    = "HTTP"
      redirect = {
        port        = 443
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]

  tags = local.tags
}
module "lb_int" {
  source  = "registry.terraform.io/terraform-aws-modules/alb/aws"
  version = "~> 6.10.0"

  name                       = "${local.lb_name}-int"
  load_balancer_type         = "application"
  internal                   = true
  vpc_id                     = try(module.vpc[0].vpc_id, var.vpc_id)
  subnets                    = try(module.vpc[0].private_subnets, var.private_subnet_ids)
  security_groups            = [module.lb_int_sg.security_group_id]
  drop_invalid_header_fields = true

  idle_timeout = 660

  access_logs = var.bucket_logging.enabled ? {
    bucket  = var.bucket_logging.create_log_bucket ? module.log_bucket.s3_bucket_id : var.bucket_logging.log_bucket
    prefix  = "lb"
    enabled = true
  } : { bucket = "", enabled = false }

  target_groups = [for target in local.targets : merge(target, { name = "${local.lb_name}-int-${target["name"]}${random_string.lb_id[target["name"]].result}" })]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    },
    {
      port               = 1234
      protocol           = "HTTP"
      target_group_index = 1
    },
    {
      port               = 8000
      protocol           = "HTTP"
      target_group_index = 2
    }
  ]

  tags = local.tags
}
resource "aws_route53_record" "external" {
  count   = var.route53_enabled ? 1 : 0
  zone_id = var.create_route53_external_zone ? aws_route53_zone.external[0].id : data.aws_route53_zone.external[0].id
  name    = local.r53_record
  type    = "A"
  alias {
    name                   = module.lb_ext.lb_dns_name
    zone_id                = module.lb_ext.lb_zone_id
    evaluate_target_health = true
  }
}
resource "aws_route53_zone" "internal" {
  count = var.create_route53_internal_zone ? 1 : 0
  name  = "datagrok.${var.name}.${var.environment}.internal"
  tags  = local.tags
  vpc {
    vpc_id = try(module.vpc[0].vpc_id, var.vpc_id)
  }
}
resource "aws_route53_record" "internal" {
  zone_id = var.create_route53_internal_zone ? aws_route53_zone.internal[0].id : var.route53_internal_zone
  name    = "datagrok.datagrok.${var.name}.${var.environment}.internal"
  type    = "A"
  alias {
    name                   = module.lb_int.lb_dns_name
    zone_id                = module.lb_int.lb_zone_id
    evaluate_target_health = true
  }
}
resource "aws_route53_record" "grok_connect" {
  zone_id = var.create_route53_internal_zone ? aws_route53_zone.internal[0].id : var.route53_internal_zone
  name    = "grok_connect.datagrok.${var.name}.${var.environment}.internal"
  type    = "A"
  alias {
    name                   = module.lb_int.lb_dns_name
    zone_id                = module.lb_int.lb_zone_id
    evaluate_target_health = true
  }
}
resource "aws_route53_record" "grok_spawner" {
  zone_id = var.create_route53_internal_zone ? aws_route53_zone.internal[0].id : var.route53_internal_zone
  name    = "grok_spawner.datagrok.${var.name}.${var.environment}.internal"
  type    = "A"
  alias {
    name                   = module.lb_int.lb_dns_name
    zone_id                = module.lb_int.lb_zone_id
    evaluate_target_health = true
  }
}

provider "aws" {
  alias  = "datagrok-cloudwatch-r53-external"
  region = "us-east-1"
}

resource "aws_cloudwatch_log_group" "external" {
  provider          = aws.datagrok-cloudwatch-r53-external
  count             = var.route53_enabled && var.enable_route53_logging && var.create_route53_external_zone ? 1 : 0
  name              = "/aws/route53/${aws_route53_zone.external[0].name}"
  retention_in_days = 7
  #checkov:skip=CKV_AWS_158:The KMS key is configurable
  kms_key_id = var.custom_kms_key ? try(module.kms[0].key_arn, var.kms_key) : null
  tags       = local.tags
}

data "aws_iam_policy_document" "external" {
  count = var.route53_enabled && var.enable_route53_logging && var.create_route53_external_zone ? 1 : 0
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:log-group:/aws/route53/*"]
    principals {
      identifiers = ["route53.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "external" {
  provider        = aws.datagrok-cloudwatch-r53-external
  count           = var.route53_enabled && var.enable_route53_logging && var.create_route53_external_zone ? 1 : 0
  policy_document = data.aws_iam_policy_document.external[0].json
  policy_name     = "${var.name}-${var.environment}-route53"
}

resource "aws_route53_query_log" "external" {
  count                    = var.route53_enabled && var.enable_route53_logging && var.create_route53_external_zone ? 1 : 0
  depends_on               = [aws_cloudwatch_log_resource_policy.external]
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.external[0].arn
  zone_id                  = aws_route53_zone.external[0].zone_id
}
