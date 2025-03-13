
resource "aws_service_discovery_private_dns_namespace" "rabbitmq_ns" {
  name        = "${local.ecs_name}.local"
  description = "Namespace for RabbitMQ"
  vpc         = try(module.vpc[0].vpc_id, var.vpc_id)  # Укажи свой VPC
}

resource "aws_service_discovery_service" "rabbitmq_sd" {
  name = "rabbitmq"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.rabbitmq_ns.id

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

resource "aws_ecs_task_definition" "rabbitmq_task" {
  family = "${local.ecs_name}_rabbitmq"
  requires_compatibilities = ["EC2", "FARGATE"]  # Поддержка обоих типов запуска
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.exec.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name  = "rabbitmq"
      image = "${var.docker_rabbitmq_image}:${var.docker_rabbitmq_tag}"
      cpu   = 256
      memory = 512
      essential = true
      portMappings = [
        {
          containerPort = 5672
          hostPort      = 5672
        },
        {
          containerPort = 15672
          hostPort      = 15672
        }
      ]
      environment = [
        { name = "RABBITMQ_DEFAULT_USER", value = var.rabbitmq_username },
        { name = "RABBITMQ_DEFAULT_PASS", value = var.rabbitmq_password }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.create_cloudwatch_log_group ? aws_cloudwatch_log_group.ecs[0].name : var.cloudwatch_log_group_name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "rabbitmq"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "rabbitmq" {
  name            = "${local.ecs_name}_rabbitmq"
  cluster         = module.ecs.cluster_arn
  task_definition = aws_ecs_task_definition.rabbitmq_task.arn
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
  launch_type     = var.ecs_launch_type

  network_configuration {
    subnets          = try(module.vpc[0].private_subnets, var.private_subnet_ids)
    security_groups  = [aws_security_group.rabbitmq_sg.id]
    assign_public_ip = var.ecs_launch_type == "FARGATE" ? true : false
  }


  service_registries {
    registry_arn = aws_service_discovery_service.rabbitmq_sd.arn
  }
}

resource "aws_security_group" "rabbitmq_sg" {
  name_prefix = "rabbitmq-"
  vpc_id                 = try(module.vpc[0].vpc_id, var.vpc_id)
  ingress {
    from_port   = 5672
    to_port     = 5672
    protocol    = "tcp"
    cidr_blocks = [try(module.vpc[0].vpc_cidr_block, var.cidr)]  # Разрешаем только внутри VPC
  }

  ingress {
    from_port   = 15672
    to_port     = 15672
    protocol    = "tcp"
    cidr_blocks = [try(module.vpc[0].vpc_cidr_block, var.cidr)]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [try(module.vpc[0].vpc_cidr_block, var.cidr)]
  }
}
