resource "aws_security_group" "rabbitmq" {
  name_prefix            = "${var.environment}-rabbitmq"
  description            = "Container"
  vpc_id                 = try(module.vpc[0].vpc_id, var.vpc_id)
  revoke_rules_on_delete = true
}

resource "aws_security_group_rule" "rabbit_sg_allow_ingress_5671" {
  type                     = "ingress"
  from_port                = 5671
  to_port                  = 5671
  protocol                 = "tcp"
  cidr_blocks               = [try(module.vpc[0].vpc_cidr_block, var.cidr)]
  security_group_id        = aws_security_group.rabbitmq.id
  description              = "from containers"
}

resource "aws_security_group_rule" "rabbit_sg_allow_egress_5671" {
  type                     = "egress"
  from_port                = 5671
  to_port                  = 5671
  protocol                 = "tcp"
  cidr_blocks               = [try(module.vpc[0].vpc_cidr_block, var.cidr)]
  security_group_id        = aws_security_group.rabbitmq.id
  description              = "to containers"
}


resource "aws_mq_broker" "rabbit" {
  broker_name = "${local.rabbitmq_name}-mq"

  engine_type = "RabbitMQ"
  engine_version             = var.rabbitmq_version
  host_instance_type         = var.rabbitmq_instance_type
  security_groups            = [aws_security_group.rabbitmq.id]
  auto_minor_version_upgrade = true
  subnet_ids          = try([module.vpc[0].private_subnets[0]], var.private_subnet_ids)
  publicly_accessible = false
  apply_immediately   = true
  maintenance_window_start_time {
    day_of_week = "SUNDAY"
    time_of_day = "08:00"
    time_zone   = "UTC"
  }
  user {
    username = var.rabbitmq_username
    password = var.rabbitmq_password
  }
  logs {
    general = true
  }

  #   lifecycle {
  #     ignore_changes = [engine_version]
  #   }
}

