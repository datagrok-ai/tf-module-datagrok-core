module "sns_topic" {
  source            = "registry.terraform.io/terraform-aws-modules/sns/aws"
  version           = "~> 3.3.0"
  create_sns_topic  = var.monitoring_alarms && var.monitoring_email_alerts && !try(length(var.monitoring_sns_topic_arn) > 0, false) || var.monitoring_email_alerts_datagrok
  name              = local.sns_topic_name
  display_name      = "Datagrok SNS topic"
  kms_master_key_id = local.create_kms ? module.kms[0].key_id : null
  tags              = local.tags
}

resource "aws_sns_topic_subscription" "email" {
  for_each = var.monitoring_alarms && var.monitoring_email_alerts || var.monitoring_email_alerts_datagrok ? toset(
    compact(
      concat(
        var.monitoring_email_alerts_datagrok ? ["monitoring@datagrok.ai"] : [],
        var.monitoring_email_alerts ? var.monitoring_email_recipients : []
      )
    )
  ) : []
  topic_arn = try(length(var.monitoring_sns_topic_arn) > 0, false) ? var.monitoring_sns_topic_arn : module.sns_topic.sns_topic_arn
  protocol  = "email"
  endpoint  = each.key
}

# Encrypt the URL, storing encryption here will show it in logs and in tfstate
# https://www.terraform.io/docs/state/sensitive-data.html
resource "aws_kms_ciphertext" "slack_url" {
  count     = var.monitoring_alarms && var.monitoring_slack_alerts && local.create_kms ? 1 : 0
  plaintext = var.monitoring_slack_webhook_url
  key_id    = local.create_kms ? module.kms[0].key_id : null
}

module "notify_slack" {
  source  = "registry.terraform.io/terraform-aws-modules/notify-slack/aws"
  version = "~> 5.4.0"

  create               = var.monitoring_alarms && var.monitoring_slack_alerts
  sns_topic_name       = local.sns_topic_name
  sns_topic_kms_key_id = local.create_kms ? module.kms[0].key_id : null
  sns_topic_tags       = local.tags
  kms_key_arn          = local.create_kms ? module.kms[0].key_id : null
  slack_webhook_url    = local.create_kms ? aws_kms_ciphertext.slack_url[0].ciphertext_blob : var.monitoring_slack_webhook_url
  slack_channel        = var.monitoring_slack_channel
  slack_username       = var.monitoring_slack_username
  slack_emoji          = var.monitoring_slack_emoji
}

resource "aws_cloudwatch_metric_alarm" "datagrok_task_count" {
  count               = var.monitoring_alarms && var.ecs_cluster_insights ? 1 : 0
  alarm_name          = "${local.ecs_name}-datagrok-task-count"
  comparison_operator = "LessThanThreshold"
  threshold           = "1"
  evaluation_periods  = "1"
  treat_missing_data  = "ignore"
  alarm_description   = "This metric monitors ${local.ecs_name} ECS tasks count"
  alarm_actions = compact([
    var.monitoring_slack_alerts ?
    module.notify_slack.slack_topic_arn :
    "",
    var.monitoring_email_alerts ?
    module.sns_topic.sns_topic_arn :
    "",
    try(length(var.monitoring_sns_topic_arn) > 0, false) ?
    var.monitoring_sns_topic_arn :
    ""
  ])
  tags = local.tags

  metric_query {
    id          = "expression"
    expression  = "IF(desired > running, 0, 1)"
    label       = "Task Failures"
    return_data = "true"
  }

  metric_query {
    id = "desired"

    metric {
      metric_name = "DesiredTaskCount"
      namespace   = "ECS/ContainerInsights"
      period      = "60"
      stat        = "Average"
      dimensions = {
        ClusterName = module.ecs.cluster_name
        ServiceName = aws_ecs_service.datagrok.name
      }
    }
  }

  metric_query {
    id = "running"

    metric {
      metric_name = "RunningTaskCount"
      namespace   = "ECS/ContainerInsights"
      period      = "60"
      stat        = "Average"
      dimensions = {
        ClusterName = module.ecs.cluster_name
        ServiceName = aws_ecs_service.datagrok.name
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "instance_count" {
  count               = var.monitoring_alarms && var.ecs_cluster_insights && var.ecs_launch_type == "EC2" ? 1 : 0
  alarm_name          = "${local.ecs_name}-ec2-instance-count"
  comparison_operator = "LessThanThreshold"
  threshold           = "1"
  evaluation_periods  = "1"
  metric_name         = "ContainerInstanceCount"
  namespace           = "ECS/ContainerInsights"
  dimensions = {
    ClusterName = module.ecs.cluster_name
  }
  period             = "60"
  statistic          = "Average"
  treat_missing_data = "ignore"
  alarm_description  = "${local.ecs_name} ECS EC2 instances count alarm"
  alarm_actions = compact([
    var.monitoring_slack_alerts ?
    module.notify_slack.slack_topic_arn :
    "",
    var.monitoring_email_alerts ?
    module.sns_topic.sns_topic_arn :
    "",
    try(length(var.monitoring_sns_topic_arn) > 0, false) ?
    var.monitoring_sns_topic_arn :
    ""
  ])
  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count               = var.monitoring_alarms ? 1 : 0
  alarm_name          = "${local.ecs_name}-ecs-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  period              = "60"
  evaluation_periods  = "1"
  datapoints_to_alarm = 1
  treat_missing_data  = "ignore"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "${local.ecs_name} ECS cluster CPU capacity alarm"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  dimensions = {
    ClusterName = module.ecs.cluster_name
  }
  alarm_actions = compact([
    var.monitoring_slack_alerts ?
    module.notify_slack.slack_topic_arn :
    "",
    var.monitoring_email_alerts ?
    module.sns_topic.sns_topic_arn :
    "",
    try(length(var.monitoring_sns_topic_arn) > 0, false) ?
    var.monitoring_sns_topic_arn :
    ""
  ])
  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "high_ram" {
  count               = var.monitoring_alarms ? 1 : 0
  alarm_name          = "${local.ecs_name}-ecs-high-ram"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  period              = "60"
  evaluation_periods  = "1"
  datapoints_to_alarm = 1
  treat_missing_data  = "ignore"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "${local.ecs_name} ECS cluster RAM capacity alarm"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  dimensions = {
    ClusterName = module.ecs.cluster_name
  }
  alarm_actions = compact([
    var.monitoring_slack_alerts ?
    module.notify_slack.slack_topic_arn :
    "",
    var.monitoring_email_alerts ?
    module.sns_topic.sns_topic_arn :
    "",
    try(length(var.monitoring_sns_topic_arn) > 0, false) ?
    var.monitoring_sns_topic_arn :
    ""
  ])
  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "lb_target" {
  count               = var.monitoring_alarms ? length(local.targets) : 0
  alarm_name          = "datagrok-lb-target-${module.lb_ext.target_group_names[count.index]}"
  comparison_operator = "LessThanThreshold"
  threshold           = "1"
  alarm_description   = "${local.ecs_name} external ALB target group ${module.lb_ext.target_group_names[count.index]} registered targets alarms"
  treat_missing_data  = "ignore"
  period              = "60"
  evaluation_periods  = "1"
  datapoints_to_alarm = 1
  statistic           = "Average"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  dimensions = {
    TargetGroup  = module.lb_ext.target_group_arn_suffixes[count.index]
    LoadBalancer = module.lb_ext.lb_arn_suffix
  }
  alarm_actions = compact([
    var.monitoring_slack_alerts ?
    module.notify_slack.slack_topic_arn :
    "",
    var.monitoring_email_alerts ?
    module.sns_topic.sns_topic_arn :
    "",
    try(length(var.monitoring_sns_topic_arn) > 0, false) ?
    var.monitoring_sns_topic_arn :
    ""
  ])
  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "datagrok_lb_5xx_count" {
  count               = var.monitoring_alarms ? 1 : 0
  alarm_name          = "${local.ecs_name}-datagrok-lb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "5"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Average API 5XX load balancer error code count is too high"
  datapoints_to_alarm = 5
  treat_missing_data  = "ignore"
  dimensions = {
    "LoadBalancer" = module.lb_ext.lb_arn_suffix
  }
  alarm_actions = compact([
    var.monitoring_slack_alerts ?
    module.notify_slack.slack_topic_arn :
    "",
    var.monitoring_email_alerts ?
    module.sns_topic.sns_topic_arn :
    "",
    try(length(var.monitoring_sns_topic_arn) > 0, false) ?
    var.monitoring_sns_topic_arn :
    ""
  ])
  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "db_high_cpu" {
  count               = var.monitoring_alarms ? 1 : 0
  alarm_name          = "${local.ecs_name}-db-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = "90"
  alarm_description   = "${local.ecs_name} RDS average CPU utilization is too high."
  treat_missing_data  = "ignore"
  dimensions = {
    DBInstanceIdentifier = module.db.db_instance_id
  }
  alarm_actions = compact([
    var.monitoring_slack_alerts ?
    module.notify_slack.slack_topic_arn :
    "",
    var.monitoring_email_alerts ?
    module.sns_topic.sns_topic_arn :
    "",
    try(length(var.monitoring_sns_topic_arn) > 0, false) ?
    var.monitoring_sns_topic_arn :
    ""
  ])
  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "db_low_cpu_credit" {
  count               = var.monitoring_alarms && length(regexall("(t2|t3)", var.rds_instance_class)) > 0 ? 1 : 0
  alarm_name          = "${local.ecs_name}-db-low-cpu-credit"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUCreditBalance"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = "100"
  alarm_description   = "${local.ecs_name} RDS average CPU credit balance is too low, a negative performance impact is imminent."
  treat_missing_data  = "ignore"
  dimensions = {
    DBInstanceIdentifier = module.db.db_instance_id
  }
  alarm_actions = compact([
    var.monitoring_slack_alerts ?
    module.notify_slack.slack_topic_arn :
    "",
    var.monitoring_email_alerts ?
    module.sns_topic.sns_topic_arn :
    "",
    try(length(var.monitoring_sns_topic_arn) > 0, false) ?
    var.monitoring_sns_topic_arn :
    ""
  ])
  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "db_high_disk_queue" {
  count               = var.monitoring_alarms ? 1 : 0
  alarm_name          = "${local.ecs_name}-db-high-disk-queue"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DiskQueueDepth"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = "64"
  alarm_description   = "${local.ecs_name} RDS average disk queue depth is too high, performance may be negatively impacted."
  treat_missing_data  = "ignore"
  dimensions = {
    DBInstanceIdentifier = module.db.db_instance_id
  }
  alarm_actions = compact([
    var.monitoring_slack_alerts ?
    module.notify_slack.slack_topic_arn :
    "",
    var.monitoring_email_alerts ?
    module.sns_topic.sns_topic_arn :
    "",
    try(length(var.monitoring_sns_topic_arn) > 0, false) ?
    var.monitoring_sns_topic_arn :
    ""
  ])
  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "db_low_disk_space" {
  count               = var.monitoring_alarms ? 1 : 0
  alarm_name          = "${local.ecs_name}-db-low-disk-space"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = "5000000000"
  alarm_description   = "${local.ecs_name} RDS average free storage space is too low and may fill up soon."
  treat_missing_data  = "ignore"
  dimensions = {
    DBInstanceIdentifier = module.db.db_instance_id
  }
  alarm_actions = compact([
    var.monitoring_slack_alerts ?
    module.notify_slack.slack_topic_arn :
    "",
    var.monitoring_email_alerts ?
    module.sns_topic.sns_topic_arn :
    "",
    try(length(var.monitoring_sns_topic_arn) > 0, false) ?
    var.monitoring_sns_topic_arn :
    ""
  ])
  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "db_anomalous_connection" {
  count               = var.monitoring_alarms ? 1 : 0
  alarm_name          = "${local.ecs_name}-db-anomaly-connections"
  comparison_operator = "GreaterThanUpperThreshold"
  evaluation_periods  = "1"
  threshold_metric_id = "e1"
  alarm_description   = "${local.ecs_name} RDS anomalous database connection count detected. Something unusual is happening."
  treat_missing_data  = "ignore"
  alarm_actions = compact([
    var.monitoring_slack_alerts ?
    module.notify_slack.slack_topic_arn :
    "",
    var.monitoring_email_alerts ?
    module.sns_topic.sns_topic_arn :
    "",
    try(length(var.monitoring_sns_topic_arn) > 0, false) ?
    var.monitoring_sns_topic_arn :
    ""
  ])
  tags = local.tags

  metric_query {
    id          = "e1"
    expression  = "ANOMALY_DETECTION_BAND(m1, 3)"
    label       = "DatabaseConnections (Expected)"
    return_data = "true"
  }

  metric_query {
    id          = "m1"
    return_data = "true"
    metric {
      metric_name = "DatabaseConnections"
      namespace   = "AWS/RDS"
      period      = "600"
      stat        = "Average"
      unit        = "Count"

      dimensions = {
        DBInstanceIdentifier = module.db.db_instance_id
      }
    }
  }
}
