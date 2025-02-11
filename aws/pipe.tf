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
  name  = "/datagrok/GROK_PARAMETERS"
  type  = "String" # Можно использовать "String", но "SecureString" лучше для паролей
  value = jsonencode(
    merge(
      {
        amazonStorageRegion = data.aws_region.current.name
        amazonStorageBucket = module.s3_bucket.s3_bucket_id
        dbServer = try(aws_route53_record.db_private_dns[0].name, module.db.db_instance_address)
        dbPort = tonumber(module.db.db_instance_port)
        db = "datagrok"
        dbLogin = "datagrok"
        dbPassword = try(random_password.db_datagrok_password[0].result, var.rds_dg_password)
        dbAdminLogin = var.rds_master_username
        dbAdminPassword = module.db.db_instance_password
        dbSsl = false
        deployDemo = false
        deployTestDemo = false
        queuePluginSettings = {
          amqpHost = split(":", split("://", aws_mq_broker.rabbit.instances[0].endpoints[0])[1])[0]
          amqpPassword = var.rabbitmq_password
          amqpPort = 5672
          amqpUser = var.rabbitmq_username
          pipeHost = aws_route53_record.grok_pipe.fqdn
          pipeKey = "test-key"
        }
      },
        var.set_admin_password ? {
        adminPassword = try(length(var.admin_password) > 0, false) ? var.admin_password : random_password.admin_password[0].result
      } : {}
    )
  )
  overwrite = true
  tags = {
    Name = "GROK_PARAMETERS"
    Environment = "production"
  }
}