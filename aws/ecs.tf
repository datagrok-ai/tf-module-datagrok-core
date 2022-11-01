resource "aws_cloudwatch_log_group" "ecs" {
  count             = var.create_cloudwatch_log_group ? 1 : 0
  name              = "/aws/ecs/${local.full_name}"
  retention_in_days = 7
  kms_key_id        = var.custom_kms_key ? (try(length(var.kms_key) > 0, false) ? var.kms_key : module.kms[0].key_arn) : null
  tags              = local.tags
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

# TODO: check AWS principal (autoscaling group) for ecs
#resource "aws_secretsmanager_secret_policy" "docker_hub" {
#  count      = try(length(var.docker_hub_secret_arn) > 0, false) ? 0 : 1
#  secret_arn = aws_secretsmanager_secret.docker_hub[0].arn
#
#  policy = <<POLICY
#{
#  "Version": "2012-10-17",
#  "Statement": [
#    {
#      "Sid": "EnableToReadTheSecret",
#      "Effect": "Allow",
#      "Action": "secretsmanager:GetSecretValue",
#      "Resource": "*"
#    }
#  ]
#}
#POLICY
#}
resource "aws_secretsmanager_secret" "docker_hub" {
  count                   = try(var.docker_hub_credentials.create_secret, false) && !var.ecr_enabled ? 1 : 0
  name_prefix             = "${local.full_name}_docker_hub"
  description             = "Docker Hub token to download images"
  kms_key_id              = var.custom_kms_key ? (try(length(var.kms_key) > 0, false) ? var.kms_key : module.kms[0].key_arn) : null
  recovery_window_in_days = 7
  tags                    = local.tags
}
resource "aws_secretsmanager_secret_version" "docker_hub" {
  count     = try(var.docker_hub_credentials.create_secret, false) && !var.ecr_enabled ? 1 : 0
  secret_id = aws_secretsmanager_secret.docker_hub[0].id
  secret_string = jsonencode({
    "username" : sensitive(var.docker_hub_credentials.user),
    "password" : sensitive(var.docker_hub_credentials.password)
  })
}

resource "aws_ecr_repository" "datagrok" {
  for_each             = var.ecr_enabled ? toset(["datagrok"]) : []
  name                 = each.key
  image_tag_mutability = var.ecr_image_tag_mutable ? "MUTABLE" : "IMMUTABLE"
  force_delete         = !var.termination_protection
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.custom_kms_key ? (try(length(var.kms_key) > 0, false) ? var.kms_key : module.kms[0].key_arn) : null
  }
  image_scanning_configuration {
    scan_on_push = var.ecr_image_scan_on_push
  }
  tags = local.tags
}

# https://github.com/mathspace/terraform-aws-ecr-docker-image/blob/master/hash.shÏ
#data "external" "datagrok_hash" {
#  for_each = var.ecr_enabled ? toset(["datagrok"]) : []
#  program  = ["${path.module}/docker_hash.sh", var.docker_datagrok_image, var.docker_datagrok_tag]
#}

resource "null_resource" "datagrok_push" {
  #  for_each = var.ecr_enabled ? toset(["datagrok"]) : []
  count = var.ecr_enabled ? 1 : 0
  triggers = {
    tag   = var.docker_datagrok_tag == "latest" ? "${var.docker_datagrok_tag}-${timestamp()}" : var.docker_datagrok_tag
    image = var.docker_datagrok_image
  }

  provisioner "local-exec" {
    command     = "${path.module}/ecr_push.sh --tag ${var.docker_datagrok_tag} --image ${var.docker_datagrok_image} --ecr ${aws_ecr_repository.datagrok["datagrok"].repository_url}"
    interpreter = ["bash", "-c"]
  }

  depends_on = [aws_ecr_repository.datagrok]
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
        "Action" = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetAuthorizationToken"
        ],
        "Condition" = {},
        "Effect"    = "Allow",
        "Resource" = toset([
          for ecr in aws_ecr_repository.datagrok : ecr.repository_url
        ])
      }
    ]
  })
}

resource "aws_iam_policy" "docker_hub" {
  count       = try(var.docker_hub_credentials.create_secret, false) && !var.ecr_enabled ? 1 : 0
  name        = "${local.ecs_name}_docker_hub"
  description = "Datagrok Dcoker Hub credentials policy for ECS task"

  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Action"    = ["secretsmanager:GetSecretValue"],
        "Condition" = {},
        "Effect"    = "Allow",
        "Resource" = [
          try(var.docker_hub_credentials.create_secret, false) ? aws_secretsmanager_secret.docker_hub[0].arn : try(var.docker_hub_credentials.secret_arn, "")
        ]
      }
    ]
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
    var.ecr_enabled ? aws_iam_policy.ecr[0].arn : aws_iam_policy.docker_hub[0].arn
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
  managed_policy_arns = compact([
    aws_iam_policy.exec.arn,
    aws_iam_policy.task.arn,
    var.ecr_enabled ? aws_iam_policy.ecr[0].arn : aws_iam_policy.docker_hub[0].arn
  ])
  #  managed_policy_arns = [aws_iam_policy.task.arn]

  tags = local.tags
}
resource "aws_ecs_task_definition" "datagrok" {
  family = "${local.ecs_name}_datagrok"

  container_definitions = jsonencode([
    {
      name = "resolv_conf"
      command = [
        "${data.aws_region.current.name}.compute.internal",
        "datagrok.${var.name}.${var.environment}.internal",
        "datagrok.${var.name}.${var.environment}.local"
      ]
      essential = false
      image     = "docker/ecs-searchdomain-sidecar:1.0"
      logConfiguration = {
        "LogDriver" : "awslogs",
        "Options" : {
          "awslogs-group" : var.create_cloudwatch_log_group ? aws_cloudwatch_log_group.ecs[0].name : var.cloudwatch_log_group_name
          "awslogs-region" : data.aws_region.current.name
          "awslogs-stream-prefix" : "datagrok"
        }
      }
      memoryReservation = 100
    },
    {
      name  = "datagrok"
      image = var.ecr_enabled ? "${aws_ecr_repository.datagrok["datagrok"].repository_url}:${var.docker_datagrok_tag}" : "${var.docker_datagrok_image}:${var.docker_datagrok_tag}"
      repositoryCredentials = {
        credentialsParameter = try(var.docker_hub_credentials.create_secret, false) ? aws_secretsmanager_secret.docker_hub[0].arn : try(var.docker_hub_credentials.secret_arn, "")
      }
      environment = [
        {
          name  = "GROK_MODE",
          value = var.datagrok_startup_mode
        },
        {
          name  = "GROK_PARAMETERS",
          value = <<EOF
{
  "amazonStorageRegion": "${data.aws_region.current.name}",
  "amazonStorageBucket": "${module.s3_bucket.s3_bucket_id}",
  "dbServer": "${module.db.db_instance_address}",
  "dbPort": "${module.db.db_instance_port}",
  "db": "datagrok",
  "dbLogin": "datagrok",
  "dbPassword": "${try(length(var.rds_dg_password) > 0, false) ? var.rds_dg_password : random_password.db_datagrok_password[0].result}",
  "dbAdminLogin": "${var.rds_master_username}",
  "dbAdminPassword": "${module.db.db_instance_password}",
  "dbSsl": false,
  "deployDemo": false,
  "deployTestDemo": false${var.set_admin_password ? "," : ""}
  ${local.admin_password_key}
}
EOF
        }
      ]
      dependsOn = [
        {
          "condition" : "SUCCESS",
          "containerName" : "resolv_conf"
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
      memoryReservation = var.datagrok_container_memory_reservation
      cpu               = var.datagrok_container_cpu
    }
  ])
  cpu                      = var.ecs_launch_type == "FARGATE" ? var.datagrok_cpu : null
  memory                   = var.ecs_launch_type == "FARGATE" ? var.datagrok_memory : null
  network_mode             = var.ecs_launch_type == "FARGATE" ? "awsvpc" : "bridge"
  execution_role_arn       = aws_iam_role.exec.arn
  task_role_arn            = aws_iam_role.task.arn
  requires_compatibilities = [var.ecs_launch_type]
}
resource "aws_service_discovery_private_dns_namespace" "datagrok" {
  count       = !try(length(var.service_discovery_namespace) > 0, false) && var.ecs_launch_type == "FARGATE" ? 1 : 0
  name        = "datagrok.${var.name}.${var.environment}.local"
  description = "Datagrok Service Discovery"
  vpc         = try(module.vpc[0].vpc_id, var.vpc_id)
}
resource "aws_service_discovery_service" "datagrok" {
  count       = var.ecs_launch_type == "FARGATE" ? 1 : 0
  name        = "datagrok"
  description = "Datagrok service discovery entry for 'datlas' server"

  dns_config {
    namespace_id = try(length(var.service_discovery_namespace) > 0, false) ? var.service_discovery_namespace : aws_service_discovery_private_dns_namespace.datagrok[0].id

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
#resource "aws_iam_policy" "service" {
#  name        = "${local.ecs_name}_service"
#  description = "Datagrok policy for ECS Service to access AWS resources"
#
#  policy = jsonencode({
#    "Version" : "2012-10-17",
#    "Statement" : [
#      {
#        "Sid" : "0",
#        "Effect" : "Allow",
#        "Action" : [
#          "elasticloadbalancing:RegisterTargets",
#          "elasticloadbalancing:DeregisterTargets"
#        ],
#        "Resource" : concat(module.lb_ext.target_group_arns, module.lb_int.target_group_arns)
#      },
#      {
#        "Sid" : "1",
#        "Effect" : "Allow",
#        "Action" : [
#          "ec2:DescribeInstances",
#          "elasticloadbalancing:DescribeTags",
#          "ec2:DescribeTags",
#          "elasticloadbalancing:DescribeLoadBalancers",
#          "elasticloadbalancing:DescribeTargetHealth",
#          "elasticloadbalancing:DescribeTargetGroups",
#          "elasticloadbalancing:DescribeInstanceHealth",
#          "ec2:DescribeInstanceStatus"
#        ],
#        "Resource" : "*"
#      }
#    ]
#  })
#}
#resource "aws_iam_role" "service" {
#  name = "${local.ecs_name}_service"
#
#  assume_role_policy  = jsonencode({
#    Version   = "2012-10-17"
#    Statement = [
#      {
#        Action    = "sts:AssumeRole"
#        Effect    = "Allow"
#        Sid       = ""
#        Principal = {
#          Service = ["ec2.amazonaws.com"]
#        }
#      },
#    ]
#  })
#  managed_policy_arns = [aws_iam_policy.service.arn]
#
#  tags = local.tags
#}
#resource "aws_iam_service_linked_role" "service" {
#  aws_service_name = "ecs.amazonaws.com"
#}
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

  #  iam_role = aws_ecs_task_definition.datagrok.network_mode == "awsvpc" ? null : aws_iam_service_linked_role.service.arn

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

data "aws_ami" "aws_optimized_ecs" {
  count       = var.ecs_launch_type == "EC2" ? 1 : 0
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
          "ecs:DiscoverPollEndpoint"
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
    var.ecr_enabled ? aws_iam_policy.ecr[0].arn : aws_iam_policy.docker_hub[0].arn
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
  ami           = try(length(var.ami_id) > 0, false) ? var.ami_id : data.aws_ami.aws_optimized_ecs[0].id
  instance_type = var.instance_type
  key_name      = try(length(var.key_pair_name) > 0, false) ? var.key_pair_name : aws_key_pair.ec2[0].key_name
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
    kms_key_id  = var.custom_kms_key ? (try(length(var.kms_key) > 0, false) ? var.kms_key : module.kms[0].key_arn) : null
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
