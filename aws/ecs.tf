resource "aws_cloudwatch_log_group" "ecs" {
  count             = var.create_cloudwatch_log_group ? 1 : 0
  name              = "/aws/ecs/${local.full_name}"
  retention_in_days = 7
  #checkov:skip=CKV_AWS_158:The KMS key is configurable
  kms_key_id = var.custom_kms_key ? try(module.kms[0].key_arn, var.kms_key) : null
  tags       = local.tags
}
module "sg" {
  source  = "registry.terraform.io/terraform-aws-modules/security-group/aws"
  version = "~> 4.12.0"

  name        = local.ecs_name
  description = "${local.ecs_name} Datagrok ECS Security Group"
  vpc_id      = try(module.vpc[0].vpc_id, var.vpc_id)

  egress_with_cidr_blocks = var.egress_rules
  ingress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "Access from within Security Group. Internal communications."
      cidr_blocks = try(module.vpc[0].vpc_cidr_block, var.cidr)
    },
  ]
}
module "ecs" {
  source  = "registry.terraform.io/terraform-aws-modules/ecs/aws"
  version = "~> 4.1.1"

  cluster_name = local.ecs_name

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name     = var.create_cloudwatch_log_group ? aws_cloudwatch_log_group.ecs[0].name : var.cloudwatch_log_group_name
        cloud_watch_encryption_enabled = var.custom_kms_key
      }
    }
  }

  cluster_settings = {
    name  = "containerInsights"
    value = var.ecs_cluster_insights ? "enabled" : "disabled"
  }

  tags = local.tags
}
resource "random_password" "db_datagrok_password" {
  count   = try(length(var.rds_dg_password) > 0, false) ? 0 : 1
  length  = 16
  special = false
}
resource "random_password" "admin_password" {
  count   = var.set_admin_password && !try(length(var.admin_password) > 0, false) ? 1 : 0
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "docker_hub" {
  count       = try(var.docker_hub_credentials.create_secret, false) && !var.ecr_enabled && var.ecs_launch_type != "FARGATE" ? 1 : 0
  name_prefix = "${local.full_name}_docker_hub"
  description = "Docker Hub token to download images"
  #checkov:skip=CKV_AWS_149:The KMS key is configurable
  kms_key_id              = var.custom_kms_key ? try(module.kms[0].key_arn, var.kms_key) : null
  recovery_window_in_days = 7
  tags                    = local.tags
}
resource "aws_secretsmanager_secret_version" "docker_hub" {
  count     = try(var.docker_hub_credentials.create_secret, false) && !var.ecr_enabled && var.ecs_launch_type != "FARGATE" ? 1 : 0
  secret_id = aws_secretsmanager_secret.docker_hub[0].id
  secret_string = jsonencode({
    "username" : sensitive(var.docker_hub_credentials.user),
    "password" : sensitive(var.docker_hub_credentials.password)
  })
}

resource "aws_ecr_repository" "ecr" {
  for_each             = var.ecr_enabled ? local.images : {}
  name                 = each.key
  image_tag_mutability = "IMMUTABLE"
  force_delete         = !var.termination_protection
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.custom_kms_key ? try(module.kms[0].key_arn, var.kms_key) : null
  }
  image_scanning_configuration {
    scan_on_push = var.ecr_image_scan_on_push
  }
  tags = local.tags
}

resource "aws_ecr_repository_policy" "ecr" {
  for_each   = var.ecr_enabled && var.ecr_principal_restrict_access ? local.images : {}
  repository = aws_ecr_repository.ecr[each.key].name
  policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = concat([data.aws_caller_identity.current.arn], var.ecr_policy_principal)
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetLifecyclePolicy",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
      }
    ]
  })
}

resource "null_resource" "ecr_push" {
  for_each = var.ecr_enabled ? local.images : {}
  triggers = {
    tag   = each.value["tag"]
    image = each.value["image"]
  }

  provisioner "local-exec" {
    command     = "${path.module}/ecr_push.sh --tag ${each.value["tag"]} --image ${each.value["image"]} --ecr ${aws_ecr_repository.ecr[each.key].repository_url}"
    interpreter = ["bash", "-c"]
  }

  depends_on = [aws_ecr_repository.ecr]
}

resource "aws_iam_policy" "exec" {
  name        = "${local.ecs_name}_exec"
  description = "Datagrok execution policy for ECS task"

  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Action" = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Effect" = "Allow",
        "Resource" = [
          var.create_cloudwatch_log_group ? aws_cloudwatch_log_group.ecs[0].arn : var.cloudwatch_log_group_arn,
          "${var.create_cloudwatch_log_group ? aws_cloudwatch_log_group.ecs[0].arn : var.cloudwatch_log_group_arn}:log-stream:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "ecr" {
  count       = var.ecr_enabled ? 1 : 0
  name        = "${local.ecs_name}_ecr"
  description = "Datagrok ECR pull policy for ECS task"

  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Action" : "ecr:GetAuthorizationToken",
        "Condition" = {},
        "Effect" : "Allow",
        "Resource" : "*"
      },
      {
        "Action" = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
        ],
        "Condition" = {},
        "Effect"    = "Allow",
        "Resource" = toset([
          for ecr in aws_ecr_repository.ecr : ecr.arn
        ])
      }
    ]
  })
}

resource "aws_iam_policy" "docker_hub" {
  count       = !var.ecr_enabled && var.ecs_launch_type != "FARGATE" ? 1 : 0
  name        = "${local.ecs_name}_docker_hub"
  description = "Datagrok Docker Hub credentials policy for ECS task"

  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = concat([
      {
        Action    = ["secretsmanager:GetSecretValue"],
        Condition = {},
        Effect    = "Allow",
        Resource = [
          try(aws_secretsmanager_secret.docker_hub[0].arn, var.docker_hub_credentials.secret_arn)
        ]
      }],
      var.custom_kms_key ? [{
        Action    = ["kms:Decrypt"],
        Condition = {},
        Effect    = "Allow",
        Resource = [
          try(module.kms[0].key_arn, var.kms_key)
        ]
      }] : []
    )
  })
}

resource "aws_iam_role" "exec" {
  name = "${local.ecs_name}_exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = ["ecs-tasks.amazonaws.com", "ec2.amazonaws.com"]
        }
      },
    ]
  })
  managed_policy_arns = compact([
    aws_iam_policy.exec.arn,
    var.ecr_enabled ? aws_iam_policy.ecr[0].arn : (var.ecs_launch_type == "FARGATE" ? "" : aws_iam_policy.docker_hub[0].arn)
  ])

  tags = local.tags
}
resource "aws_iam_policy" "task" {
  name        = "${local.ecs_name}_task"
  description = "Datagrok policy to access AWS resources from tasks"

  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Action" = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        "Condition" = {},
        "Effect"    = "Allow",
        "Resource" = [
          module.s3_bucket.s3_bucket_arn,
          "${module.s3_bucket.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}
resource "aws_iam_role" "task" {
  name = "${local.ecs_name}_task"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = ["ecs-tasks.amazonaws.com", "ec2.amazonaws.com"]
        }
      },
    ]
  })
  managed_policy_arns = compact(concat([
    aws_iam_policy.exec.arn,
    aws_iam_policy.task.arn,
    var.ecr_enabled ? aws_iam_policy.ecr[0].arn : (var.ecs_launch_type == "FARGATE" ? "" : aws_iam_policy.docker_hub[0].arn)
  ], var.task_iam_policies))

  tags = local.tags
}

data "aws_route53_zone" "internal" {
  count   = var.create_route53_internal_zone ? 0 : 1
  zone_id = var.route53_internal_zone
}
resource "aws_service_discovery_private_dns_namespace" "datagrok" {
  count       = var.service_discovery_namespace.create && var.ecs_launch_type == "FARGATE" ? 1 : 0
  name        = "datagrok.${var.name}.${var.environment}.cn.internal"
  description = "Datagrok Service Discovery"
  vpc         = try(module.vpc[0].vpc_id, var.vpc_id)
}

resource "aws_ecs_task_definition" "datagrok" {
  family = "${local.ecs_name}_datagrok"
  container_definitions = jsonencode(concat(
    var.ecs_launch_type == "FARGATE" ? [
      {
        name = "resolv_conf"
        command = [
          "${data.aws_region.current.name}.compute.internal",
          var.create_route53_internal_zone ? aws_route53_zone.internal[0].name : data.aws_route53_zone.internal[0].name,
          "datagrok.${var.name}.${var.environment}.cn.internal"
        ]
        essential = false
        image     = "${var.ecr_enabled ? aws_ecr_repository.ecr["ecs-searchdomain-sidecar-${var.name}-${var.environment}"].repository_url : local.images["ecs-searchdomain-sidecar-${var.name}-${var.environment}"]["image"]}:${local.images["ecs-searchdomain-sidecar-${var.name}-${var.environment}"]["tag"]}"
        logConfiguration = {
          LogDriver = "awslogs"
          Options = {
            awslogs-group         = var.create_cloudwatch_log_group ? aws_cloudwatch_log_group.ecs[0].name : var.cloudwatch_log_group_name
            awslogs-region        = data.aws_region.current.name
            awslogs-stream-prefix = "datagrok"
          }
        }
        memoryReservation = 100
      }
    ] : [],
    [
      merge({
        name  = "datagrok"
        image = "${var.ecr_enabled ? aws_ecr_repository.ecr["datagrok"].repository_url : var.docker_datagrok_image}:${var.ecr_enabled ? local.images["datagrok"]["tag"] : (var.ecr_enabled ? local.images["datagrok"]["tag"] : var.docker_datagrok_tag)}"
        environment = [
          {
            name  = "GROK_MODE",
            value = var.datagrok_startup_mode
          },
          {
            name = "GROK_PARAMETERS"
            value = jsonencode(
              merge(
                {
                  amazonStorageRegion = data.aws_region.current.name
                  amazonStorageBucket = module.s3_bucket.s3_bucket_id
                  dbServer            = try(aws_route53_record.db_private_dns[0].name, module.db.db_instance_address)
                  dbPort              = tonumber(module.db.db_instance_port)
                  db                  = "datagrok"
                  dbLogin             = "datagrok"
                  dbPassword          = try(random_password.db_datagrok_password[0].result, var.rds_dg_password)
                  dbAdminLogin        = var.rds_master_username
                  dbAdminPassword     = module.db.db_instance_password
                  dbSsl               = false
                  deployDemo          = false
                  deployTestDemo      = false
                  queuePluginSettings = {
                    amqpHost     = "rabbitmq.${local.ecs_name}.local"
                    amqpPassword = var.rabbitmq_password
                    amqpPort     = var.amqpPort
                    amqpUser     = var.rabbitmq_username
                    pipeHost     = "${aws_route53_record.grok_pipe.fqdn}"
                    pipeKey      = var.pipeKey
                    tls          = var.amqpTLS
                  }
                },
                var.set_admin_password ? {
                  adminPassword = try(length(var.admin_password) > 0, false) ? var.admin_password : random_password.admin_password[0].result
                } : {}
              )
            )
          }
        ]
        essential = true
        logConfiguration = {
          "LogDriver" : "awslogs",
          "Options" : {
            "awslogs-group" : var.create_cloudwatch_log_group ? aws_cloudwatch_log_group.ecs[0].name : var.cloudwatch_log_group_name
            "awslogs-region" : data.aws_region.current.name
            "awslogs-stream-prefix" : "datagrok"
          }
        }
        portMappings = [
          {
            hostPort      = var.ecs_launch_type == "FARGATE" ? 8080 : 0
            protocol      = "tcp"
            containerPort = 8080
          }
        ]
        memoryReservation = var.ecs_launch_type == "FARGATE" ? var.datagrok_memory - 200 : var.datagrok_container_memory_reservation
        cpu               = var.datagrok_container_cpu
        }, var.ecr_enabled ? {} : (var.ecs_launch_type == "FARGATE" ? {} : {
          repositoryCredentials = {
            credentialsParameter = try(aws_secretsmanager_secret.docker_hub[0].arn, var.docker_hub_credentials.secret_arn)
          }
        }), var.ecs_launch_type == "FARGATE" ? {
        dependsOn = [
          {
            "condition" : "SUCCESS",
            "containerName" : "resolv_conf"
          }
        ]
        } : {},
        var.ecs_launch_type == "FARGATE" ? {} : {
          dnsSearchDomains = compact([
            "${data.aws_region.current.name}.compute.internal",
            var.create_route53_internal_zone ? aws_route53_zone.internal[0].name : data.aws_route53_zone.internal[0].name,
          ])
        }
      )
  ]))
  cpu                      = var.ecs_launch_type == "FARGATE" ? var.datagrok_cpu : null
  memory                   = var.ecs_launch_type == "FARGATE" ? var.datagrok_memory : null
  network_mode             = var.ecs_launch_type == "FARGATE" ? "awsvpc" : "bridge"
  execution_role_arn       = aws_iam_role.exec.arn
  task_role_arn            = aws_iam_role.task.arn
  requires_compatibilities = [var.ecs_launch_type]
  depends_on               = [null_resource.ecr_push]
}
resource "aws_service_discovery_service" "datagrok" {
  count       = var.ecs_launch_type == "FARGATE" ? 1 : 0
  name        = "datagrok"
  description = "Datagrok service discovery entry for 'datlas' server"

  dns_config {
    namespace_id = var.service_discovery_namespace.create ? aws_service_discovery_private_dns_namespace.datagrok[0].id : var.service_discovery_namespace.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
resource "aws_ecs_service" "datagrok" {
  name            = "${local.ecs_name}_datagrok"
  cluster         = module.ecs.cluster_arn
  task_definition = aws_ecs_task_definition.datagrok.arn
  launch_type     = var.ecs_launch_type

  desired_count                      = 1
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  scheduling_strategy                = "REPLICA"
  deployment_controller {
    type = "ECS"
  }
  enable_execute_command = true
  force_new_deployment   = true
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  dynamic "service_registries" {
    for_each = var.ecs_launch_type == "FARGATE" ? [
      { registry_arn : aws_service_discovery_service.datagrok[0].arn }
    ] : []
    content {
      registry_arn = service_registries.value["registry_arn"]
    }
  }

  load_balancer {
    target_group_arn = module.lb_ext.target_group_arns[0]
    container_name   = "datagrok"
    container_port   = 8080
  }
  load_balancer {
    target_group_arn = module.lb_int.target_group_arns[0]
    container_name   = "datagrok"
    container_port   = 8080
  }

  dynamic "network_configuration" {
    for_each = var.ecs_launch_type == "FARGATE" ? [
      {
        subnets : try(module.vpc[0].private_subnets, var.private_subnet_ids)
        security_groups : [module.sg.security_group_id]
      }
    ] : []
    content {
      subnets          = network_configuration.value["subnets"]
      security_groups  = network_configuration.value["security_groups"]
      assign_public_ip = false
    }
  }
}

resource "aws_ecs_task_definition" "grok_connect" {
  family = "${local.ecs_name}_grok_connect"

  container_definitions = jsonencode(concat(
    var.ecs_launch_type == "FARGATE" ? [
      {
        name = "resolv_conf"
        command = [
          "${data.aws_region.current.name}.compute.internal",
          var.create_route53_internal_zone ? aws_route53_zone.internal[0].name : data.aws_route53_zone.internal[0].name,
          "datagrok.${var.name}.${var.environment}.cn.internal"
        ]
        essential = false
        image     = "${var.ecr_enabled ? aws_ecr_repository.ecr["ecs-searchdomain-sidecar-${var.name}-${var.environment}"].repository_url : local.images["ecs-searchdomain-sidecar-${var.name}-${var.environment}"]["image"]}:${local.images["ecs-searchdomain-sidecar-${var.name}-${var.environment}"]["tag"]}"
        logConfiguration = {
          LogDriver = "awslogs"
          Options = {
            awslogs-group         = var.create_cloudwatch_log_group ? aws_cloudwatch_log_group.ecs[0].name : var.cloudwatch_log_group_name
            awslogs-region        = data.aws_region.current.name
            awslogs-stream-prefix = "grok_connect"
          }
        }
        memoryReservation = 100
      }
    ] : [],
    [
      merge({
        name      = "grok_connect"
        image     = "${var.ecr_enabled ? aws_ecr_repository.ecr["grok_connect"].repository_url : var.docker_grok_connect_image}:${var.ecr_enabled ? local.images["grok_connect"]["tag"] : (var.ecr_enabled ? local.images["grok_connect"]["tag"] : var.docker_grok_connect_tag)}"
        essential = true
        logConfiguration = {
          "LogDriver" : "awslogs",
          "Options" : {
            "awslogs-group" : var.create_cloudwatch_log_group ? aws_cloudwatch_log_group.ecs[0].name : var.cloudwatch_log_group_name
            "awslogs-region" : data.aws_region.current.name
            "awslogs-stream-prefix" : "grok_connect"
          }
        }
        portMappings = [
          {
            hostPort      = var.ecs_launch_type == "FARGATE" ? 1234 : 0
            protocol      = "tcp"
            containerPort = 1234
          }
        ]
        memoryReservation = var.ecs_launch_type == "FARGATE" ? var.grok_connect_memory - 200 : var.grok_connect_container_memory_reservation
        cpu               = var.grok_connect_container_cpu
        }, var.ecr_enabled ? {} : (var.ecs_launch_type == "FARGATE" ? {} : {
          repositoryCredentials = {
            credentialsParameter = try(aws_secretsmanager_secret.docker_hub[0].arn, var.docker_hub_credentials.secret_arn)
          }
        }), var.ecs_launch_type == "FARGATE" ? {
        dependsOn = [
          {
            "condition" : "SUCCESS",
            "containerName" : "resolv_conf"
          }
        ]
        } : {},
        var.ecs_launch_type == "FARGATE" ? {} : {
          dnsSearchDomains = compact([
            "${data.aws_region.current.name}.compute.internal",
            var.create_route53_internal_zone ? aws_route53_zone.internal[0].name : data.aws_route53_zone.internal[0].name,
          ])
        }
      )
  ]))
  cpu                      = var.ecs_launch_type == "FARGATE" ? var.grok_connect_cpu : null
  memory                   = var.ecs_launch_type == "FARGATE" ? var.grok_connect_memory : null
  network_mode             = var.ecs_launch_type == "FARGATE" ? "awsvpc" : "bridge"
  execution_role_arn       = aws_iam_role.exec.arn
  task_role_arn            = aws_iam_role.task.arn
  requires_compatibilities = [var.ecs_launch_type]
  depends_on               = [null_resource.ecr_push]
}
resource "aws_service_discovery_service" "grok_connect" {
  count       = var.ecs_launch_type == "FARGATE" ? 1 : 0
  name        = "grok_connect"
  description = "Datagrok service discovery entry for 'grok_connect'"

  dns_config {
    namespace_id = var.service_discovery_namespace.create ? aws_service_discovery_private_dns_namespace.datagrok[0].id : var.service_discovery_namespace.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
resource "aws_ecs_service" "grok_connect" {
  name            = "${local.ecs_name}_grok_connect"
  cluster         = module.ecs.cluster_arn
  task_definition = aws_ecs_task_definition.grok_connect.arn
  launch_type     = var.ecs_launch_type

  desired_count                      = 1
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  scheduling_strategy                = "REPLICA"
  deployment_controller {
    type = "ECS"
  }
  enable_execute_command = true
  force_new_deployment   = true
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  dynamic "service_registries" {
    for_each = var.ecs_launch_type == "FARGATE" ? [
      { registry_arn : aws_service_discovery_service.grok_connect[0].arn }
    ] : []
    content {
      registry_arn = service_registries.value["registry_arn"]
    }
  }

  load_balancer {
    target_group_arn = module.lb_int.target_group_arns[1]
    container_name   = "grok_connect"
    container_port   = 1234
  }

  dynamic "network_configuration" {
    for_each = var.ecs_launch_type == "FARGATE" ? [
      {
        subnets : try(module.vpc[0].private_subnets, var.private_subnet_ids)
        security_groups : [module.sg.security_group_id]
      }
    ] : []
    content {
      subnets          = network_configuration.value["subnets"]
      security_groups  = network_configuration.value["security_groups"]
      assign_public_ip = false
    }
  }
}

resource "aws_ecs_task_definition" "smtp" {
  count  = var.smtp_server ? 1 : 0
  family = "${local.ecs_name}_smtp"

  container_definitions = jsonencode([
    merge({
      name  = "smtp"
      image = "${var.ecr_enabled ? aws_ecr_repository.ecr["smtp-${var.name}-${var.environment}"].repository_url : local.images["smtp-${var.name}-${var.environment}"]["image"]}:${local.images["smtp-${var.name}-${var.environment}"]["tag"]}"
      environment = [
        {
          name  = "RELAY_HOST",
          value = var.smtp_relay_host
        },
        {
          name  = "RELAY_PORT",
          value = var.smtp_relay_port
        },
        {
          name  = "RELAY_USERNAME",
          value = var.smtp_relay_username
        },
        {
          name  = "RELAY_PASSWORD",
          value = var.smtp_relay_password
        }
      ]
      essential = true
      logConfiguration = {
        "LogDriver" : "awslogs",
        "Options" : {
          "awslogs-group" : var.create_cloudwatch_log_group ? aws_cloudwatch_log_group.ecs[0].name : var.cloudwatch_log_group_name
          "awslogs-region" : data.aws_region.current.name
          "awslogs-stream-prefix" : "smtp"
        }
      }
      portMappings = [
        {
          hostPort      = var.ecs_launch_type == "FARGATE" ? 25 : 0
          protocol      = "tcp"
          containerPort = 25
        }
      ]
      memoryReservation = 100
      cpu               = 100
      }, var.ecr_enabled ? {} : (var.ecs_launch_type == "FARGATE" ? {} : {
        repositoryCredentials = {
          credentialsParameter = try(aws_secretsmanager_secret.docker_hub[0].arn, var.docker_hub_credentials.secret_arn)
        }
      }),
    )
  ])
  cpu                      = var.ecs_launch_type == "FARGATE" ? 256 : null
  memory                   = var.ecs_launch_type == "FARGATE" ? 512 : null
  network_mode             = var.ecs_launch_type == "FARGATE" ? "awsvpc" : "bridge"
  execution_role_arn       = aws_iam_role.exec.arn
  task_role_arn            = aws_iam_role.task.arn
  requires_compatibilities = [var.ecs_launch_type]
  depends_on               = [null_resource.ecr_push]
}
resource "aws_service_discovery_service" "smtp" {
  count       = var.ecs_launch_type == "FARGATE" && var.smtp_server ? 1 : 0
  name        = "smtp"
  description = "Datagrok service discovery entry for 'smtp'"

  dns_config {
    namespace_id = var.service_discovery_namespace.create ? aws_service_discovery_private_dns_namespace.datagrok[0].id : var.service_discovery_namespace.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
resource "aws_ecs_service" "smtp" {
  count           = var.smtp_server ? 1 : 0
  name            = "${local.ecs_name}_smtp"
  cluster         = module.ecs.cluster_arn
  task_definition = aws_ecs_task_definition.smtp[0].arn
  launch_type     = var.ecs_launch_type

  desired_count                      = 1
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  scheduling_strategy                = "REPLICA"
  deployment_controller {
    type = "ECS"
  }
  enable_execute_command = true
  force_new_deployment   = true
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  dynamic "service_registries" {
    for_each = var.ecs_launch_type == "FARGATE" ? [
      { registry_arn : aws_service_discovery_service.smtp[0].arn }
    ] : []
    content {
      registry_arn = service_registries.value["registry_arn"]
    }
  }

  dynamic "network_configuration" {
    for_each = var.ecs_launch_type == "FARGATE" ? [
      {
        subnets : try(module.vpc[0].private_subnets, var.private_subnet_ids)
        security_groups : [module.sg.security_group_id]
      }
    ] : []
    content {
      subnets          = network_configuration.value["subnets"]
      security_groups  = network_configuration.value["security_groups"]
      assign_public_ip = false
    }
  }
}


resource "aws_iam_policy" "grok_spawner_kaniko_ecr" {
  count       = var.grok_spawner_docker_build_enabled ? 1 : 0
  name        = "${local.ecs_name}_grok_spawner_kaniko_ecr"
  description = "Grok Spawner Kaniko ECR policy"

  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Action" : [
          "ecr:GetAuthorizationToken"
        ]
        "Condition" = {},
        "Effect" : "Allow",
        "Resource" : "*"
      },
      {
        "Action" = [
          "ecr:CompleteLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:InitiateLayerUpload",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:TagResource"
        ],
        "Condition" = {},
        "Effect"    = "Allow",
        "Resource" = [
          "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/datagrok/*"
        ]
      },
      {
        "Action" = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage"
        ],
        "Condition" = {},
        "Effect"    = "Allow",
        "Resource" = [
          "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/datagrok/*"
        ]
      }
    ]
  })
}


resource "aws_iam_role" "grok_spawner_task" {
  name = "${local.ecs_name}_grok_spawner_task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = ["ecs-tasks.amazonaws.com", "ec2.amazonaws.com"]
        }
      },
    ]
  })

  inline_policy {
    name = "${local.ecs_name}_grok_spawner"
    policy = jsonencode({
      "Version" = "2012-10-17",
      "Statement" = [
        {
          "Action" = [
            "ecs:ListTasks",
            "ecs:ListServices"
          ],
          "Condition" = {
            "ArnLike" : {
              "ecs:cluster" : distinct(compact([
                module.ecs.cluster_arn,
                try(length(var.grok_spawner_cvm_ecs_cluster) > 0, false) ? "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${var.grok_spawner_cvm_ecs_cluster}" : ""
              ]))
            }
          },
          "Effect"   = "Allow",
          "Resource" = "*"
        },
        {
          "Action" = [
            "ecs:RegisterTaskDefinition",
          ],
          "Condition" = {
            "StringEquals" : {
              "aws:RequestTag/caller" : ["grok_spawner"]
            }
          },
          "Effect"   = "Allow",
          "Resource" = "*"
        },
        {
          "Action" = [
            "ecs:DescribeTaskDefinition",
            "ecs:ListTaskDefinitions",
            "ecs:DeregisterTaskDefinition"
          ],
          "Condition" = {},
          "Effect"    = "Allow",
          "Resource"  = "*"
        },
        {
          "Effect" = "Allow",
          "Action" : [
            "ecs:DescribeServices",
            "ecs:UpdateService",
            "ecs:DeleteService"
          ],
          "Condition" = {
            "ArnLike" : {
              "ecs:cluster" : distinct(compact([
                module.ecs.cluster_arn,
                try(length(var.grok_spawner_cvm_ecs_cluster) > 0, false) ? "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${var.grok_spawner_cvm_ecs_cluster}" : ""
              ]))
            }
          },
          "Resource" : distinct(compact([
            "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/${module.ecs.cluster_name}/*",
            try(length(var.grok_spawner_cvm_ecs_cluster) > 0, false) ? "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/${var.grok_spawner_cvm_ecs_cluster}/*" : ""
          ]))
        },
        {
          "Effect" = "Allow",
          "Action" : [
            "ecs:CreateService",
            "ecs:TagResource"
          ],
          "Condition" = {
            "ArnLike" : {
              "ecs:cluster" : distinct(compact([
                module.ecs.cluster_arn,
                try(length(var.grok_spawner_cvm_ecs_cluster) > 0, false) ? "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${var.grok_spawner_cvm_ecs_cluster}" : ""
              ]))
            },
            "StringEquals" : {
              "aws:RequestTag/caller" : ["grok_spawner"]
            }
          },
          "Resource" : distinct(compact([
            "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/${module.ecs.cluster_name}/*",
            try(length(var.grok_spawner_cvm_ecs_cluster) > 0, false) ? "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/${var.grok_spawner_cvm_ecs_cluster}/*" : ""
          ]))
        },
        {
          "Effect" = "Allow",
          "Action" : [
            "ecs:DescribeTasks"
          ],
          "Condition" = {
            "ArnLike" : {
              "ecs:cluster" : distinct(compact([
                module.ecs.cluster_arn,
                try(length(var.grok_spawner_cvm_ecs_cluster) > 0, false) ? "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${var.grok_spawner_cvm_ecs_cluster}" : ""
              ]))
            }
          },
          "Resource" = distinct(compact([
            "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task/${module.ecs.cluster_name}/*",
            try(length(var.grok_spawner_cvm_ecs_cluster) > 0, false) ? "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task/${var.grok_spawner_cvm_ecs_cluster}/*" : ""
          ]))
        },
        {
          "Action" = [
            "logs:GetLogEvents"
          ],
          "Effect" = "Allow",
          "Resource" = [
            "${var.create_cloudwatch_log_group ? aws_cloudwatch_log_group.ecs[0].arn : var.cloudwatch_log_group_arn}:log-stream:grok_spawner/*"
          ]
        },
        {
          "Action" = [
            "ecs:DescribeClusters"
          ],
          "Effect" = "Allow",
          "Resource" = distinct(compact([
            module.ecs.cluster_arn,
            try(length(var.grok_spawner_cvm_ecs_cluster) > 0, false) ? "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${var.grok_spawner_cvm_ecs_cluster}" : ""
          ]))
        },
        {
          "Action" = [
            "ecs:DescribeContainerInstances"
          ],
          "Effect" = "Allow",
          "Condition" = {
            "ArnLike" : {
              "ecs:cluster" : distinct(compact([
                module.ecs.cluster_arn,
                try(length(var.grok_spawner_cvm_ecs_cluster) > 0, false) ? "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${var.grok_spawner_cvm_ecs_cluster}" : ""
              ]))
            }
          },
          "Resource" = distinct(compact([
            "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:container-instance/${module.ecs.cluster_name}/*",
            try(length(var.grok_spawner_cvm_ecs_cluster) > 0, false) ? "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:container-instance/${var.grok_spawner_cvm_ecs_cluster}/*" : ""
          ]))
        },
        {
          "Action" = [
            "ec2:DescribeInstances"
          ],
          "Effect" = "Allow",
          "Condition" = {
            "StringEquals" : {
              "ec2:Region" : [data.aws_region.current.name]
            }
          },
          "Resource" : "*"
        }
      ]
    })
  }

  inline_policy {
    name = "${local.ecs_name}_grok_spawner_tags"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : "ecs:TagResource",
          "Resource" : [
            "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task-definition/*",
            "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/${module.ecs.cluster_name}/*"
          ],
          "Condition" : {
            "StringEquals" : {
              "ecs:CreateAction" : [
                "CreateService",
                "RegisterTaskDefinition",
                "UpdateService"
              ]
            }
          }
        }
      ]
    })
  }
  inline_policy {
    name = "${local.ecs_name}_grok_spawner_logs"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "logs:GetLogEvents",
            "logs:DescribeLogStreams",
            "logs:DescribeLogGroups"]
          "Resource" : [
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ecs/*",
          ]
        }
      ]
    })
  }

  dynamic "inline_policy" {
    for_each = var.grok_spawner_docker_build_enabled ? { enabled = true } : {}
    content {
      name = "${local.ecs_name}_grok_spawner_ecr"

      policy = jsonencode({
        "Version" = "2012-10-17",
        "Statement" = [
          {
            "Action" : [
              "ecr:GetAuthorizationToken"
            ]
            "Condition" = {},
            "Effect" : "Allow",
            "Resource" : "*"
          },
          {
            "Action" : [
              "ecr:CreateRepository"
            ]
            "Condition" = {
              "StringEquals" : {
                "aws:RequestTag/builder" : ["grok_spawner"]
              }
            },
            "Effect" : "Allow",
            "Resource" : "*"
          },
          {
            "Action" = [
              "ecr:TagResource"
            ],
            "Condition" = {},
            "Effect"    = "Allow",
            "Condition" = {
              "StringEquals" : {
                "aws:RequestTag/builder" : ["grok_spawner"]
              }
            },
            "Resource" = [
              "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/datagrok/*"
            ]
          },
          {
            "Action" = [
              "ecr:DescribeRepositories",
              "ecr:ListImages"
            ],
            "Condition" = {},
            "Effect"    = "Allow",
            "Resource" = [
              "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/datagrok/*"
            ]
          }
        ]
      })
    }
  }

  dynamic "inline_policy" {
    for_each = var.grok_spawner_docker_build_enabled ? { enabled = true } : {}
    content {
      name = "${local.ecs_name}_grok_spawner_kaniko"
      policy = jsonencode({
        "Version" = "2012-10-17",
        "Statement" = [
          {
            "Effect" = "Allow",
            "Action" : [
              "ecs:RunTask"
            ],
            "Condition" = {
              "ArnLike" : {
                "ecs:cluster" : distinct(compact([
                  module.ecs.cluster_arn,
                  try(length(var.grok_spawner_cvm_ecs_cluster) > 0, false) ? "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${var.grok_spawner_cvm_ecs_cluster}" : ""
                ]))
              }
            },
            "Resource" : ["${aws_ecs_task_definition.grok_spawner_kaniko.arn_without_revision}:*"
            ]
          },
          {
            "Effect" = "Allow",
            "Action" : [
              "iam:PassRole"
            ],
            "Resource" : [
              aws_iam_role.grok_spawner_kaniko_task.arn,
              aws_iam_role.exec.arn,
              aws_iam_role.grok_spawner_exec.arn
            ]
          }
        ]
      })
    }

  }

  managed_policy_arns = compact([
    aws_iam_policy.exec.arn,
    aws_iam_policy.task.arn,
    var.ecr_enabled ? aws_iam_policy.ecr[0].arn : (var.ecs_launch_type == "FARGATE" ? "" : aws_iam_policy.docker_hub[0].arn),
  ])

  tags = local.tags
}
resource "aws_iam_role" "grok_spawner_kaniko_task" {
  name = "${local.ecs_name}_grok_spawner_kaniko_task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = ["ecs-tasks.amazonaws.com", "ec2.amazonaws.com"]
        }
      },
    ]
  })
  managed_policy_arns = compact([
    aws_iam_policy.exec.arn,
    aws_iam_policy.task.arn,
    var.ecr_enabled ? aws_iam_policy.ecr[0].arn : (var.ecs_launch_type == "FARGATE" ? "" : aws_iam_policy.docker_hub[0].arn),
    var.grok_spawner_docker_build_enabled ? aws_iam_policy.grok_spawner_kaniko_ecr[0].arn : ""
  ])

  tags = local.tags
}
resource "aws_iam_policy" "grok_spawner_exec" {
  count       = var.grok_spawner_docker_build_enabled ? 1 : 0
  name        = "${local.ecs_name}_grok_spawner_exec"
  description = "Datagrok ECR pull policy for ECS task run by Grok Spawner"

  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Action" : "ecr:GetAuthorizationToken",
        "Condition" = {},
        "Effect" : "Allow",
        "Resource" : "*"
      },
      {
        "Action" = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
        ],
        "Condition" = {},
        "Effect"    = "Allow",
        "Resource"  = "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/datagrok/*"
      }
    ]
  })
}
resource "aws_iam_role" "grok_spawner_exec" {
  name = "${local.ecs_name}_grok_spawner_exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = ["ecs-tasks.amazonaws.com", "ec2.amazonaws.com"]
        }
      },
    ]
  })
  managed_policy_arns = compact([
    aws_iam_policy.exec.arn,
    var.grok_spawner_docker_build_enabled ? aws_iam_policy.grok_spawner_exec[0].arn : ""
  ])

  tags = local.tags
}
resource "aws_ecs_task_definition" "grok_spawner" {
  family = "${local.ecs_name}_grok_spawner"

  container_definitions = jsonencode(concat(
    var.ecs_launch_type == "FARGATE" ? [
      {
        name = "resolv_conf"
        command = [
          "${data.aws_region.current.name}.compute.internal",
          var.create_route53_internal_zone ? aws_route53_zone.internal[0].name : data.aws_route53_zone.internal[0].name,
          "datagrok.${var.name}.${var.environment}.cn.internal"
        ]
        essential = false
        image     = "${var.ecr_enabled ? aws_ecr_repository.ecr["ecs-searchdomain-sidecar-${var.name}-${var.environment}"].repository_url : local.images["ecs-searchdomain-sidecar-${var.name}-${var.environment}"]["image"]}:${local.images["ecs-searchdomain-sidecar-${var.name}-${var.environment}"]["tag"]}"
        logConfiguration = {
          LogDriver = "awslogs"
          Options = {
            awslogs-group         = var.create_cloudwatch_log_group ? aws_cloudwatch_log_group.ecs[0].name : var.cloudwatch_log_group_name
            awslogs-region        = data.aws_region.current.name
            awslogs-stream-prefix = "grok_spawner"
          }
        }
        memoryReservation = 100
      }
    ] : [],
    [
      merge({
        name      = "grok_spawner"
        image     = "${var.ecr_enabled ? aws_ecr_repository.ecr["grok_spawner"].repository_url : var.docker_grok_spawner_image}:${var.ecr_enabled ? local.images["grok_spawner"]["tag"] : (var.ecr_enabled ? local.images["grok_spawner"]["tag"] : var.docker_grok_spawner_tag)}"
        essential = true
        environment = [
          {
            name  = "GROK_SPAWNER_ENVIRONMENT",
            value = local.full_name
          },
          {
            name  = "GROK_SPAWNER_LOG_LEVEL",
            value = var.grok_spawner_log_level
          },
          {
            name  = "GROK_SPAWNER_PROFILE_MEMORY",
            value = var.grok_spawner_log_level == "debug" ? "true" : "false"
          },
          {
            name  = "GROK_SPAWNER_X_API_KEY",
            value = "test-x-api-key"
          },
          {
            name  = "GROK_SPAWNER_DATAGROK_ECS__CLUSTER",
            value = module.ecs.cluster_name
          },
          {
            name  = "GROK_SPAWNER_DATAGROK_ECS__CLUSTER_REGION"
            value = data.aws_region.current.name
          },
          {
            name  = "GROK_SPAWNER_DATAGROK_ECS__SUBNETS",
            value = jsonencode(try(module.vpc[0].private_subnets, var.private_subnet_ids))
          },
          {
            name  = "GROK_SPAWNER_CVM_ECS__SUBNETS",
            value = jsonencode(try(module.vpc[0].private_subnets, var.private_subnet_ids))
          },
          {
            name  = "GROK_SPAWNER_DATAGROK_ECS__SECURITY_GROUPS",
            value = jsonencode([module.sg.security_group_id])
          },
          {
            name  = "GROK_SPAWNER_CVM_ECS__SECURITY_GROUPS",
            value = jsonencode([module.sg.security_group_id])
          },
          {
            name  = "GROK_SPAWNER_DATAGROK_ECS__EXEC_ROLE",
            value = aws_iam_role.grok_spawner_exec.arn
          },
          {
            name  = "GROK_SPAWNER_DATAGROK_ECS__LOG_GROUP",
            value = var.create_cloudwatch_log_group ? aws_cloudwatch_log_group.ecs[0].arn : var.cloudwatch_log_group_arn
          },
          {
            name  = "GROK_SPAWNER_CVM_ECS__CLUSTER",
            value = try(length(var.grok_spawner_cvm_ecs_cluster) > 0, false) ? var.grok_spawner_cvm_ecs_cluster : module.ecs.cluster_name
          },
          {
            name  = "GROK_SPAWNER_CVM_ECS__CLUSTER_REGION",
            value = try(length(var.grok_spawner_cvm_ecs_cluster_region) > 0, false) ? var.grok_spawner_cvm_ecs_cluster_region : data.aws_region.current.name
          },
          {
            name  = "GROK_SPAWNER_CVM_ECS__LAUNCH_TYPE",
            value = try(length(var.grok_spawner_cvm_launch_type) > 0, false) ? var.grok_spawner_cvm_launch_type : var.ecs_launch_type
          },
          {
            name  = "GROK_SPAWNER_DATAGROK_ECS__LAUNCH_TYPE",
            value = var.ecs_launch_type
          },
          {
            name  = "GROK_SPAWNER_DATAGROK_ECS__KANIKO_S3_BUCKET"
            value = local.s3_name
          },
          {
            name  = "GROK_SPAWNER_DATAGROK_ECS__KANIKO_TASK_DEFINITION",
            value = aws_ecs_task_definition.grok_spawner_kaniko.arn
          },
          {
            name  = "GROK_SPAWNER_CVM_ECS__KANIKO_S3_BUCKET"
            value = local.s3_name
          },
          {
            name  = "GROK_SPAWNER_CVM_ECS__KANIKO_TASK_DEFINITION",
            value = aws_ecs_task_definition.grok_spawner_kaniko.arn
          }
        ]
        logConfiguration = {
          "LogDriver" : "awslogs",
          "Options" : {
            "awslogs-group" : var.create_cloudwatch_log_group ? aws_cloudwatch_log_group.ecs[0].name : var.cloudwatch_log_group_name
            "awslogs-region" : data.aws_region.current.name
            "awslogs-stream-prefix" : "grok_spawner"
          }
        }
        portMappings = [
          {
            hostPort      = var.ecs_launch_type == "FARGATE" ? 8000 : 0
            protocol      = "tcp"
            containerPort = 8000
          }
        ]
        memoryReservation = var.ecs_launch_type == "FARGATE" ? var.grok_spawner_memory - 200 : var.grok_spawner_container_memory_reservation
        cpu               = var.grok_spawner_container_cpu
        }, var.ecr_enabled ? {} : (var.ecs_launch_type == "FARGATE" ? {} : {
          repositoryCredentials = {
            credentialsParameter = try(aws_secretsmanager_secret.docker_hub[0].arn, var.docker_hub_credentials.secret_arn)
          }
        }), var.ecs_launch_type == "FARGATE" ? {} : {
        dnsSearchDomains = compact([
          "${data.aws_region.current.name}.compute.internal",
          var.create_route53_internal_zone ? aws_route53_zone.internal[0].name : data.aws_route53_zone.internal[0].name,
        ])
        }, var.ecs_launch_type == "FARGATE" ? {
        dependsOn = [
          {
            "condition" : "SUCCESS",
            "containerName" : "resolv_conf"
          }
        ]
        } : {}
      )
  ]))
  cpu                      = var.ecs_launch_type == "FARGATE" ? var.grok_spawner_cpu : null
  memory                   = var.ecs_launch_type == "FARGATE" ? var.grok_spawner_memory : null
  network_mode             = var.ecs_launch_type == "FARGATE" ? "awsvpc" : "bridge"
  execution_role_arn       = aws_iam_role.exec.arn
  task_role_arn            = aws_iam_role.grok_spawner_task.arn
  requires_compatibilities = [var.ecs_launch_type]
  depends_on               = [null_resource.ecr_push]
}
resource "aws_ecs_task_definition" "grok_spawner_kaniko" {
  family = "${local.ecs_name}_grok_spawner_kaniko"

  container_definitions = jsonencode([
    {
      name      = "grok_spawner_kaniko"
      image     = "${var.ecr_enabled ? aws_ecr_repository.ecr["kaniko-${var.name}-${var.environment}"].repository_url : local.images["kaniko-${var.name}-${var.environment}"]["image"]}:${local.images["kaniko-${var.name}-${var.environment}"]["tag"]}"
      essential = true
      logConfiguration = {
        "LogDriver" : "awslogs",
        "Options" : {
          "awslogs-group" : var.create_cloudwatch_log_group ? aws_cloudwatch_log_group.ecs[0].name : var.cloudwatch_log_group_name
          "awslogs-region" : data.aws_region.current.name
          "awslogs-stream-prefix" : "grok_spawner_kaniko"
        }
      },
      portMappings = [
        {
          hostPort      = 8000
          protocol      = "tcp"
          containerPort = 8000
        }
      ]
    }
  ])
  cpu                      = 1024
  memory                   = 5120
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.exec.arn
  task_role_arn            = aws_iam_role.grok_spawner_kaniko_task.arn
  requires_compatibilities = ["FARGATE"]
  depends_on               = [null_resource.ecr_push]
  ephemeral_storage {
    size_in_gib = 100
  }
}
resource "aws_service_discovery_service" "grok_spawner" {
  count       = var.ecs_launch_type == "FARGATE" ? 1 : 0
  name        = "grok_spawner"
  description = "Datagrok service discovery entry for 'grok_spawner'"

  dns_config {
    namespace_id = var.service_discovery_namespace.create ? aws_service_discovery_private_dns_namespace.datagrok[0].id : var.service_discovery_namespace.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
resource "aws_ecs_service" "grok_spawner" {
  name            = "${local.ecs_name}_grok_spawner"
  cluster         = module.ecs.cluster_arn
  task_definition = aws_ecs_task_definition.grok_spawner.arn
  launch_type     = var.ecs_launch_type

  desired_count                      = 1
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  scheduling_strategy                = "REPLICA"
  deployment_controller {
    type = "ECS"
  }
  enable_execute_command = true
  force_new_deployment   = true
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  dynamic "service_registries" {
    for_each = var.ecs_launch_type == "FARGATE" ? [
      { registry_arn : aws_service_discovery_service.grok_spawner[0].arn }
    ] : []
    content {
      registry_arn = service_registries.value["registry_arn"]
    }
  }

  load_balancer {
    target_group_arn = module.lb_int.target_group_arns[2]
    container_name   = "grok_spawner"
    container_port   = 8000
  }

  dynamic "network_configuration" {
    for_each = var.ecs_launch_type == "FARGATE" ? [
      {
        subnets : try(module.vpc[0].private_subnets, var.private_subnet_ids)
        security_groups : [module.sg.security_group_id]
      }
    ] : []
    content {
      subnets          = network_configuration.value["subnets"]
      security_groups  = network_configuration.value["security_groups"]
      assign_public_ip = false
    }
  }
}

data "aws_ami" "aws_optimized_ecs" {
  count       = !try(length(var.ami_id) > 0, false) && var.ecs_launch_type == "EC2" ? 1 : 0
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm*ebs"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["591542846629"] # AWS
}
resource "aws_key_pair" "ec2" {
  count      = var.ecs_launch_type == "EC2" && try(length(var.public_key) > 0, false) && !try(length(var.key_pair_name) > 0, false) ? 1 : 0
  key_name   = local.full_name
  public_key = var.public_key
}
resource "aws_iam_policy" "ec2" {
  name        = "${local.ec2_name}_ec2"
  description = "Datagrok execution policy for EC2 instance to run ECS tasks"

  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Action" = [
          "ec2:DescribeTags",
          "ecs:DiscoverPollEndpoint",
          "ecs:ListContainerInstances"
        ],
        "Effect"   = "Allow",
        "Resource" = "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ecs:Poll",
          "ecs:StartTelemetrySession",
          "ecs:UpdateContainerInstancesState",
          "ecs:RegisterContainerInstance",
          "ecs:Submit*",
          "ecs:DeregisterContainerInstance"
        ],
        "Resource" : [
          module.ecs.cluster_arn,
          "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:container-instance/${module.ecs.cluster_name}/*"
        ]
      },
    ]
  })
}
resource "aws_iam_role" "ec2" {
  name = "${local.ec2_name}_ec2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = ["ec2.amazonaws.com"]
        }
      },
    ]
  })
  managed_policy_arns = compact([
    aws_iam_policy.exec.arn,
    aws_iam_policy.ec2.arn,
    var.ecr_enabled ? aws_iam_policy.ecr[0].arn : (var.ecs_launch_type == "FARGATE" ? "" : aws_iam_policy.docker_hub[0].arn)
  ])

  tags = local.tags
}
resource "aws_iam_instance_profile" "ec2_profile" {
  count = var.ecs_launch_type == "EC2" ? 1 : 0
  name  = "${local.ec2_name}_ec2_profile"
  role  = aws_iam_role.ec2.name
}
resource "aws_instance" "ec2" {
  count         = var.ecs_launch_type == "EC2" ? 1 : 0
  ami           = try(data.aws_ami.aws_optimized_ecs[0].id, var.ami_id)
  instance_type = var.instance_type
  key_name      = try(aws_key_pair.ec2[0].key_name, var.key_pair_name)
  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    ecs_cluster_name = module.ecs.cluster_name
  }))
  availability_zone                    = data.aws_availability_zones.available.names[0]
  subnet_id                            = try(module.vpc[0].private_subnets[0], var.private_subnet_ids[0])
  associate_public_ip_address          = false
  vpc_security_group_ids               = [module.sg.security_group_id]
  disable_api_stop                     = var.termination_protection
  disable_api_termination              = var.termination_protection
  source_dest_check                    = true
  instance_initiated_shutdown_behavior = "stop"
  monitoring                           = var.ec2_detailed_monitoring_enabled
  iam_instance_profile                 = aws_iam_instance_profile.ec2_profile[0].name
  metadata_options {
    http_endpoint          = "enabled"
    http_tokens            = "optional"
    instance_metadata_tags = "enabled"
  }
  maintenance_options {
    auto_recovery = "default"
  }
  root_block_device {
    encrypted   = true
    kms_key_id  = var.custom_kms_key ? try(module.kms[0].key_arn, var.kms_key) : null
    volume_type = "gp3"
    throughput  = try(length(var.root_volume_throughput) > 0, false) ? var.root_volume_throughput : null
    volume_size = 50
  }
  ebs_optimized = true
  tags          = merge({ Name = local.ec2_name }, local.tags)

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

resource "aws_ecs_task_definition" "grok_pipe" {
  family = "${local.ecs_name}_grok_pipe"

  container_definitions = jsonencode(concat(
    var.ecs_launch_type == "FARGATE" ? [
      {
        name = "resolv_conf"
        command = [
          "${data.aws_region.current.name}.compute.internal",
          var.create_route53_internal_zone ? aws_route53_zone.internal[0].name : data.aws_route53_zone.internal[0].name,
          "datagrok.${var.name}.${var.environment}.cn.internal"
        ]
        essential = false
        image     = "${var.ecr_enabled ? aws_ecr_repository.ecr["ecs-searchdomain-sidecar-${var.name}-${var.environment}"].repository_url : local.images["ecs-searchdomain-sidecar-${var.name}-${var.environment}"]["image"]}:${local.images["ecs-searchdomain-sidecar-${var.name}-${var.environment}"]["tag"]}"
        logConfiguration = {
          LogDriver = "awslogs"
          Options = {
            awslogs-group         = var.create_cloudwatch_log_group ? aws_cloudwatch_log_group.ecs[0].name : var.cloudwatch_log_group_name
            awslogs-region        = data.aws_region.current.name
            awslogs-stream-prefix = "grok_pipe"
          }
        }
        memoryReservation = 100
      }
    ] : [],
    [
      merge({
        name      = "grok_pipe"
        image     = "${var.ecr_enabled ? aws_ecr_repository.ecr["grok_pipe"].repository_url : var.docker_grok_pipe_image}:${var.ecr_enabled ? local.images["grok_pipe"]["tag"] : (var.ecr_enabled ? local.images["grok_pipe"]["tag"] : var.docker_grok_pipe_tag)}"
        essential = true
        environment = [{
          name  = "API_KEY",
          value = var.pipeKey

          },
          {
            name  = "GROK_PARAMETERS"
            value = aws_ssm_parameter.grok_parameters.value
          }
        ]
        logConfiguration = {
          "LogDriver" : "awslogs",
          "Options" : {
            "awslogs-group" : var.create_cloudwatch_log_group ? aws_cloudwatch_log_group.ecs[0].name : var.cloudwatch_log_group_name
            "awslogs-region" : data.aws_region.current.name
            "awslogs-stream-prefix" : "grok_pipe"
          }
        }
        portMappings = [
          {
            hostPort      = var.ecs_launch_type == "FARGATE" ? 3000 : 0
            protocol      = "tcp"
            containerPort = 3000
          }
        ]
        memoryReservation = var.ecs_launch_type == "FARGATE" ? var.grok_pipe_memory - 200 : var.grok_pipe_container_memory_reservation
        cpu               = var.grok_pipe_container_cpu
        }, var.ecr_enabled ? {} : (var.ecs_launch_type == "FARGATE" ? {} : {
          repositoryCredentials = {
            credentialsParameter = try(aws_secretsmanager_secret.docker_hub[0].arn, var.docker_hub_credentials.secret_arn)
          }
        }), var.ecs_launch_type == "FARGATE" ? {
        dependsOn = [
          {
            "condition" : "SUCCESS",
            "containerName" : "resolv_conf"
          }
        ]
        } : {},
        var.ecs_launch_type == "FARGATE" ? {} : {
          dnsSearchDomains = compact([
            "${data.aws_region.current.name}.compute.internal",
            var.create_route53_internal_zone ? aws_route53_zone.internal[0].name : data.aws_route53_zone.internal[0].name,
          ])
        }
      )
  ]))
  cpu                      = var.ecs_launch_type == "FARGATE" ? var.grok_pipe_cpu : null
  memory                   = var.ecs_launch_type == "FARGATE" ? var.grok_pipe_memory : null
  network_mode             = var.ecs_launch_type == "FARGATE" ? "awsvpc" : "bridge"
  execution_role_arn       = aws_iam_role.exec.arn
  task_role_arn            = aws_iam_role.task.arn
  requires_compatibilities = [var.ecs_launch_type]
  depends_on               = [null_resource.ecr_push]
}
resource "aws_service_discovery_service" "grok_pipe" {
  count       = var.ecs_launch_type == "FARGATE" ? 1 : 0
  name        = "grok_pipe"
  description = "Datagrok service discovery entry for 'grok_pipe'"

  dns_config {
    namespace_id = var.service_discovery_namespace.create ? aws_service_discovery_private_dns_namespace.datagrok[0].id : var.service_discovery_namespace.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
resource "aws_ecs_service" "grok_pipe" {
  name            = "${local.ecs_name}_grok_pipe"
  cluster         = module.ecs.cluster_arn
  task_definition = aws_ecs_task_definition.grok_pipe.arn
  launch_type     = var.ecs_launch_type

  desired_count                      = 1
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  scheduling_strategy                = "REPLICA"
  deployment_controller {
    type = "ECS"
  }
  enable_execute_command = true
  force_new_deployment   = true

  dynamic "service_registries" {
    for_each = var.ecs_launch_type == "FARGATE" ? [
      { registry_arn : aws_service_discovery_service.grok_pipe[0].arn }
    ] : []
    content {
      registry_arn = service_registries.value["registry_arn"]
    }
  }

  load_balancer {
    target_group_arn = module.lb_int.target_group_arns[3]
    container_name   = "grok_pipe"
    container_port   = 3000
  }

  dynamic "network_configuration" {
    for_each = var.ecs_launch_type == "FARGATE" ? [
      {
        subnets : try(module.vpc[0].private_subnets, var.private_subnet_ids)
        security_groups : [module.sg.security_group_id]
      }
    ] : []
    content {
      subnets          = network_configuration.value["subnets"]
      security_groups  = network_configuration.value["security_groups"]
      assign_public_ip = false
    }
  }
}
resource "aws_ssm_parameter" "grok_parameters" {
  name = "/datagrok/GROK_PARAMETERS"
  type = "String" # Можно использовать "String", но "SecureString" лучше для паролей
  value = jsonencode(
    merge(
      {
        amazonStorageRegion = data.aws_region.current.name
        amazonStorageBucket = module.s3_bucket.s3_bucket_id
        dbServer            = try(aws_route53_record.db_private_dns[0].name, module.db.db_instance_address)
        dbPort              = tonumber(module.db.db_instance_port)
        db                  = "datagrok"
        dbLogin             = "datagrok"
        dbPassword          = try(random_password.db_datagrok_password[0].result, var.rds_dg_password)
        dbAdminLogin        = var.rds_master_username
        dbAdminPassword     = module.db.db_instance_password
        dbSsl               = false
        deployDemo          = false
        deployTestDemo      = false
        queuePluginSettings = {
          amqpHost     = "rabbitmq.${local.ecs_name}.local"
          amqpPassword = var.rabbitmq_password
          amqpPort     = 5672
          amqpUser     = var.rabbitmq_username
          pipeHost     = aws_route53_record.grok_pipe.fqdn
          pipeKey      = "test-key"
        }
      },
      var.set_admin_password ? {
        adminPassword = try(length(var.admin_password) > 0, false) ? var.admin_password : random_password.admin_password[0].result
      } : {}
    )
  )
  overwrite = true
  tags = {
    Name        = "GROK_PARAMETERS"
    Environment = "production"
  }
}