## Usage

```
module "datagrok_core" {
  # We recommend to specify an exact tag as ref argument
  source = "git@github.com:datagrok-ai/tf-module-datagrok-core.git//aws?ref=main"

  name                = "datagrok"
  environment         = "example"
  domain_name         = "datagrok.example"
  docker_hub_credentials = {
    create_secret = true
    user          = "exampleUser"
    password      = "examplePassword"
  }
}
```
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.36.1 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.4.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.36.1 |
| <a name="provider_aws.datagrok-cloudwatch-r53-external"></a> [aws.datagrok-cloudwatch-r53-external](#provider\_aws.datagrok-cloudwatch-r53-external) | >= 4.36.1 |
| <a name="provider_null"></a> [null](#provider\_null) | >= 3.2.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.4.3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_acm"></a> [acm](#module\_acm) | registry.terraform.io/terraform-aws-modules/acm/aws | ~> 3.5.0 |
| <a name="module_db"></a> [db](#module\_db) | registry.terraform.io/terraform-aws-modules/rds/aws | ~> 5.0.3 |
| <a name="module_db_sg"></a> [db\_sg](#module\_db\_sg) | registry.terraform.io/terraform-aws-modules/security-group/aws | ~> 4.12.0 |
| <a name="module_ecs"></a> [ecs](#module\_ecs) | registry.terraform.io/terraform-aws-modules/ecs/aws | ~> 4.1.1 |
| <a name="module_kms"></a> [kms](#module\_kms) | registry.terraform.io/terraform-aws-modules/kms/aws | ~> 1.1.0 |
| <a name="module_lb_ext"></a> [lb\_ext](#module\_lb\_ext) | registry.terraform.io/terraform-aws-modules/alb/aws | ~> 6.10.0 |
| <a name="module_lb_ext_sg"></a> [lb\_ext\_sg](#module\_lb\_ext\_sg) | registry.terraform.io/terraform-aws-modules/security-group/aws | ~> 4.12.0 |
| <a name="module_lb_int"></a> [lb\_int](#module\_lb\_int) | registry.terraform.io/terraform-aws-modules/alb/aws | ~> 6.10.0 |
| <a name="module_lb_int_sg"></a> [lb\_int\_sg](#module\_lb\_int\_sg) | registry.terraform.io/terraform-aws-modules/security-group/aws | ~> 4.12.0 |
| <a name="module_log_bucket"></a> [log\_bucket](#module\_log\_bucket) | registry.terraform.io/terraform-aws-modules/s3-bucket/aws | ~> 3.3.0 |
| <a name="module_notify_slack"></a> [notify\_slack](#module\_notify\_slack) | registry.terraform.io/terraform-aws-modules/notify-slack/aws | ~> 5.4.0 |
| <a name="module_s3_bucket"></a> [s3\_bucket](#module\_s3\_bucket) | registry.terraform.io/terraform-aws-modules/s3-bucket/aws | ~>3.3.0 |
| <a name="module_sg"></a> [sg](#module\_sg) | registry.terraform.io/terraform-aws-modules/security-group/aws | ~> 4.12.0 |
| <a name="module_sns_topic"></a> [sns\_topic](#module\_sns\_topic) | registry.terraform.io/terraform-aws-modules/sns/aws | ~> 3.3.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | registry.terraform.io/terraform-aws-modules/vpc/aws | ~> 3.14.2 |
| <a name="module_vpc_endpoint"></a> [vpc\_endpoint](#module\_vpc\_endpoint) | registry.terraform.io/terraform-aws-modules/vpc/aws//modules/vpc-endpoints | ~> 3.14.2 |

## Resources

| Name | Type |
|------|------|
| [aws_backup_plan.s3_backup_plan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_plan) | resource |
| [aws_backup_selection.s3_bucket_backup_selection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_selection) | resource |
| [aws_backup_vault.s3_backup_vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault) | resource |
| [aws_backup_vault_notifications.test](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault_notifications) | resource |
| [aws_cloudwatch_log_group.ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.external](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_resource_policy.external](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_resource_policy) | resource |
| [aws_cloudwatch_metric_alarm.datagrok_lb_5xx_count](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.datagrok_task_count](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.db_anomalous_connection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.db_high_cpu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.db_high_disk_queue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.db_low_cpu_credit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.db_low_disk_space](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.high_cpu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.high_ram](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.instance_count](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.lb_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.lb_target_5xx_count](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_ecr_repository.ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_ecr_repository_policy.ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository_policy) | resource |
| [aws_ecs_service.datagrok](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_service.grok_connect](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_service.grok_spawner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_service.smtp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.datagrok](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_ecs_task_definition.grok_connect](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_ecs_task_definition.grok_spawner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_ecs_task_definition.grok_spawner_kaniko](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_ecs_task_definition.smtp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_instance_profile.ec2_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.docker_hub](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.grok_spawner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.grok_spawner_ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.grok_spawner_exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.grok_spawner_kaniko](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.grok_spawner_kaniko_ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.s3_backup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.grok_spawner_exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.grok_spawner_kaniko_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.grok_spawner_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.s3_backup_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.backup_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.backup_service_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_key_pair.ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_kms_ciphertext.slack_url](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_ciphertext) | resource |
| [aws_route53_query_log.external](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_query_log) | resource |
| [aws_route53_record.external](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.grok_connect](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.grok_spawner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.internal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.external](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_route53_zone.internal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_secretsmanager_secret.docker_hub](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.docker_hub](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_service_discovery_private_dns_namespace.datagrok](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_private_dns_namespace) | resource |
| [aws_service_discovery_service.datagrok](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_service) | resource |
| [aws_service_discovery_service.grok_connect](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_service) | resource |
| [aws_service_discovery_service.grok_spawner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_service) | resource |
| [aws_service_discovery_service.smtp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_service) | resource |
| [aws_sns_topic_subscription.email](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [null_resource.ecr_push](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_password.admin_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.db_datagrok_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_pet.this](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [random_string.lb_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [aws_ami.aws_optimized_ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.external](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.vpc_endpoint_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_route53_zone.external](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_route53_zone.internal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_cert_arn"></a> [acm\_cert\_arn](#input\_acm\_cert\_arn) | ACM certificate ARN for Datagrok endpoint. If it is not set it will be created | `string` | `null` | no |
| <a name="input_acm_cert_create"></a> [acm\_cert\_create](#input\_acm\_cert\_create) | Specifies if the ACM certificate should be created. | `bool` | `true` | no |
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | Specifies the Datagrok Admin user password. If it is not specified, the random password will be generated, 16 symbols long without special characters. | `string` | `null` | no |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | The AMI ID for Datagrok EC2 instance. If it is not specified, the basic AWS ECS optimized AMI will be used. | `string` | `null` | no |
| <a name="input_bucket_logging"></a> [bucket\_logging](#input\_bucket\_logging) | Bucket Logging object.<br> `enabled` - Specifies whether Logging requests using server access logging for Datagrok S3 bucket are enabled. We recommend to set it to true for production stand.<br>`create_log_bucket` - Specifies whether the S3 log bucket will be created.<br>`log_bucket` - The name of S3 logging bucket. If it is not specified, the S3 log bucket for Datagrok S3 bucket will be created. | <pre>object({<br>    log_bucket        = optional(string)<br>    create_log_bucket = bool<br>    enabled           = bool<br>  })</pre> | <pre>{<br>  "create_log_bucket": true,<br>  "enabled": true<br>}</pre> | no |
| <a name="input_cidr"></a> [cidr](#input\_cidr) | The CIDR for the VPC. | `string` | `"10.0.0.0/17"` | no |
| <a name="input_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#input\_cloudwatch\_log\_group\_arn) | The ARM of existing CloudWatch Log Group to use with Datagrok. | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#input\_cloudwatch\_log\_group\_name) | The name of Datagrok CloudWatch Log Group. If it is not specified, the name along with the environment will be used. | `string` | `null` | no |
| <a name="input_create_cloudwatch_log_group"></a> [create\_cloudwatch\_log\_group](#input\_create\_cloudwatch\_log\_group) | Specifies if the CloudWatch Log Group should be created. If it is set to false cloudwatch\_log\_group\_arn is required. | `bool` | `true` | no |
| <a name="input_create_route53_external_zone"></a> [create\_route53\_external\_zone](#input\_create\_route53\_external\_zone) | Specifies if the Route53 external hosted zone for the domain should be created. If not specified some other DNS service should be used instead of Route53 or existing Route53 zone. | `bool` | `true` | no |
| <a name="input_create_route53_internal_zone"></a> [create\_route53\_internal\_zone](#input\_create\_route53\_internal\_zone) | Specifies if the Route53 internal hosted zone for the domain should be created. If if is set to false route53\_internal\_zone is required | `bool` | `true` | no |
| <a name="input_custom_kms_key"></a> [custom\_kms\_key](#input\_custom\_kms\_key) | Specifies whether a custom KMS key should be used to encrypt instead of the default. We recommend to set it to true for production stand. | `bool` | `false` | no |
| <a name="input_data_subnet_ids"></a> [data\_subnet\_ids](#input\_data\_subnet\_ids) | The IDs of data subnets to place resources. Required if 'vpc\_id' is specified. | `list(string)` | `[]` | no |
| <a name="input_database_subnet_group"></a> [database\_subnet\_group](#input\_database\_subnet\_group) | The ID of database subnet group to place datagrok DB. Required if 'vpc\_id' is specified. | `string` | `null` | no |
| <a name="input_datagrok_container_cpu"></a> [datagrok\_container\_cpu](#input\_datagrok\_container\_cpu) | The number of cpu units the Amazon ECS container agent reserves for the Datagrok container. | `number` | `1024` | no |
| <a name="input_datagrok_container_memory_reservation"></a> [datagrok\_container\_memory\_reservation](#input\_datagrok\_container\_memory\_reservation) | The soft limit (in MiB) of memory to reserve for the Datagrok container. | `number` | `1024` | no |
| <a name="input_datagrok_cpu"></a> [datagrok\_cpu](#input\_datagrok\_cpu) | Number of cpu units used by the Datagrok FARGATE task. The hard limit of CPU units to present for the task. | `number` | `2048` | no |
| <a name="input_datagrok_memory"></a> [datagrok\_memory](#input\_datagrok\_memory) | Amount (in MiB) of memory used by the Datagrok FARGATE task. The hard limit of memory (in MiB) to present to the task. | `number` | `4096` | no |
| <a name="input_datagrok_startup_mode"></a> [datagrok\_startup\_mode](#input\_datagrok\_startup\_mode) | Datagrok startup mode. It can be 'start' (do not deploy required resources, start the server), 'deploy' (full redeploy of the required resources on every start of the server. Use with cautious, it can destroy you existing data.), 'auto' (checks of the required resources already exists, if the are, and starts the server, otherwise it will deploy the resources before the server start.). | `string` | `"auto"` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | The database name in RDS. | `string` | `null` | no |
| <a name="input_docker_datagrok_image"></a> [docker\_datagrok\_image](#input\_docker\_datagrok\_image) | Datagrok Docker Image registry location. By default the official image from Docker Hub will be used. | `string` | `"docker.io/datagrok/datagrok"` | no |
| <a name="input_docker_datagrok_tag"></a> [docker\_datagrok\_tag](#input\_docker\_datagrok\_tag) | Tag from Docker Registry for Datagrok Docker Image | `string` | `"latest"` | no |
| <a name="input_docker_grok_connect_image"></a> [docker\_grok\_connect\_image](#input\_docker\_grok\_connect\_image) | Grok Connect Docker Image registry location. By default the official image from Docker Hub will be used. | `string` | `"docker.io/datagrok/grok_connect"` | no |
| <a name="input_docker_grok_connect_tag"></a> [docker\_grok\_connect\_tag](#input\_docker\_grok\_connect\_tag) | Tag from Docker Registry for Datagrok Grok Connect Image | `string` | `"latest"` | no |
| <a name="input_docker_grok_spawner_image"></a> [docker\_grok\_spawner\_image](#input\_docker\_grok\_spawner\_image) | Grok Spawner Docker Image registry location. By default the official image from Docker Hub will be used. | `string` | `"docker.io/datagrok/grok_spawner"` | no |
| <a name="input_docker_grok_spawner_tag"></a> [docker\_grok\_spawner\_tag](#input\_docker\_grok\_spawner\_tag) | Tag from Docker Registry for Datagrok Grok Spawner Image | `string` | `"latest"` | no |
| <a name="input_docker_hub_credentials"></a> [docker\_hub\_credentials](#input\_docker\_hub\_credentials) | Docker Hub credentials to download images.<br>`create_secret` - Specifies if new secret with Docker Hub credentials will be created.<br>`user` - Docker Hub User to access Docker Hub and download datagrok images. Can be ommited if `secret_arn` is specified<br>`password` - Docker Hub Token to access Docker Hub and download datagrok images. Can be ommited if `secret_arn` is specified<br>`secret_arn` - The ARN of AWS Secret which contains Docker Hub Token to access Docker Hub and download datagrok images. If not specified the secret will be created using `user` and `password` variables<br>Either user(`user`) - password(`password`) pair or AWS Secret ARN (`secret_arn`) should be specified. | <pre>object({<br>    create_secret = bool<br>    password      = optional(string)<br>    user          = optional(string)<br>    secret_arn    = optional(string)<br>  })</pre> | `null` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | This is the name of domain for datagrok endpoint. It is used for the external hosted zone in Route53. and to create ACM certificates. | `string` | `""` | no |
| <a name="input_ec2_detailed_monitoring_enabled"></a> [ec2\_detailed\_monitoring\_enabled](#input\_ec2\_detailed\_monitoring\_enabled) | Specifies whether Monitoring Insights for EC2 instance are enabled. We recommend to set it to true for production stand. | `bool` | `true` | no |
| <a name="input_ec2_name"></a> [ec2\_name](#input\_ec2\_name) | The name of Datagrok EC2 instance. If it is not specified, the name along with the environment will be used. | `string` | `null` | no |
| <a name="input_ecr_enabled"></a> [ecr\_enabled](#input\_ecr\_enabled) | Specifies whether terraform copy images to ECR and use it instead of `docker_<service>_image` | `bool` | `false` | no |
| <a name="input_ecr_image_scan_on_push"></a> [ecr\_image\_scan\_on\_push](#input\_ecr\_image\_scan\_on\_push) | Indicates whether images are scanned after being pushed to the repository (true) or not scanned (false). | `bool` | `true` | no |
| <a name="input_ecr_policy_principal"></a> [ecr\_policy\_principal](#input\_ecr\_policy\_principal) | List of principal ARNs which will have access to ECR. By default it is limited to the caller ARN. | `list(string)` | `[]` | no |
| <a name="input_ecr_principal_restrict_access"></a> [ecr\_principal\_restrict\_access](#input\_ecr\_principal\_restrict\_access) | Specifies whether ECR restrictive policy is enabled. We recommend to set it to true for production stand. | `bool` | `false` | no |
| <a name="input_ecs_cluster_insights"></a> [ecs\_cluster\_insights](#input\_ecs\_cluster\_insights) | Specifies whether Monitoring Insights for ECS cluster are enabled. We recommend to set it to true for production stand. | `bool` | `true` | no |
| <a name="input_ecs_launch_type"></a> [ecs\_launch\_type](#input\_ecs\_launch\_type) | Launch type for datagrok containers. FARGATE and EC2 are available options. We recommend FARGATE for production stand. | `string` | `"FARGATE"` | no |
| <a name="input_ecs_name"></a> [ecs\_name](#input\_ecs\_name) | The name of ECS cluster for Datagrok. If it is not specified, the name along with the environment will be used. | `string` | `null` | no |
| <a name="input_egress_rules"></a> [egress\_rules](#input\_egress\_rules) | List of egress rules to restrict outbound traffic for ECS cluster | `list(any)` | <pre>[<br>  {<br>    "cidr_blocks": "0.0.0.0/0",<br>    "description": "Allow all outbound traffic",<br>    "from_port": 0,<br>    "protocol": "-1",<br>    "to_port": 65535<br>  }<br>]</pre> | no |
| <a name="input_enable_flow_logs"></a> [enable\_flow\_logs](#input\_enable\_flow\_logs) | Enable Flow logs for the VPC? | `bool` | `true` | no |
| <a name="input_enable_route53_logging"></a> [enable\_route53\_logging](#input\_enable\_route53\_logging) | Specifies whether Logging requests using server access logging for Datagrok Route53 zone are enabled. We recommend to set it to true for production stand. | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment of a stand. It will be used to name resources along with the name. | `string` | n/a | yes |
| <a name="input_flow_log_cloudwatch_log_group_name_prefix"></a> [flow\_log\_cloudwatch\_log\_group\_name\_prefix](#input\_flow\_log\_cloudwatch\_log\_group\_name\_prefix) | Flow logs CloudWatch Log Group name prefix. | `string` | `"/aws/vpc-flow-log/"` | no |
| <a name="input_flow_log_log_format"></a> [flow\_log\_log\_format](#input\_flow\_log\_log\_format) | Flow logs format. | `string` | `null` | no |
| <a name="input_grok_connect_container_cpu"></a> [grok\_connect\_container\_cpu](#input\_grok\_connect\_container\_cpu) | The number of cpu units the Amazon ECS container agent reserves for the Grok Connect container. | `number` | `512` | no |
| <a name="input_grok_connect_container_memory_reservation"></a> [grok\_connect\_container\_memory\_reservation](#input\_grok\_connect\_container\_memory\_reservation) | The soft limit (in MiB) of memory to reserve for the Grok Connect container. | `number` | `512` | no |
| <a name="input_grok_connect_cpu"></a> [grok\_connect\_cpu](#input\_grok\_connect\_cpu) | Number of cpu units used by the Grok Connect FARGATE task. The hard limit of CPU units to present for the task. | `number` | `1024` | no |
| <a name="input_grok_connect_memory"></a> [grok\_connect\_memory](#input\_grok\_connect\_memory) | Amount (in MiB) of memory used by the Grok Connect FARGATE task. The hard limit of memory (in MiB) to present to the task. | `number` | `4096` | no |
| <a name="input_grok_spawner_container_cpu"></a> [grok\_spawner\_container\_cpu](#input\_grok\_spawner\_container\_cpu) | The number of cpu units the Amazon ECS container agent reserves for the Grok Spawner container. | `number` | `256` | no |
| <a name="input_grok_spawner_container_memory_reservation"></a> [grok\_spawner\_container\_memory\_reservation](#input\_grok\_spawner\_container\_memory\_reservation) | The soft limit (in MiB) of memory to reserve for the Grok Spawner container. | `number` | `256` | no |
| <a name="input_grok_spawner_cpu"></a> [grok\_spawner\_cpu](#input\_grok\_spawner\_cpu) | Number of cpu units used by the Grok Spawner FARGATE task. The hard limit of CPU units to present for the task. | `number` | `256` | no |
| <a name="input_grok_spawner_docker_build_enabled"></a> [grok\_spawner\_docker\_build\_enabled](#input\_grok\_spawner\_docker\_build\_enabled) | Specifies whether ECR policy to create repositories should be enabled for Grok Spawner to store debug images | `bool` | `true` | no |
| <a name="input_grok_spawner_memory"></a> [grok\_spawner\_memory](#input\_grok\_spawner\_memory) | Amount (in MiB) of memory used by the Grok Spawner FARGATE task. The hard limit of memory (in MiB) to present to the task. | `number` | `512` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type. The default value is the minimum recommended type. | `string` | `"t3.medium"` | no |
| <a name="input_key_pair_name"></a> [key\_pair\_name](#input\_key\_pair\_name) | Existing SSH Key Pair name for access to EC2 instance. If not set public\_key is required. | `string` | `null` | no |
| <a name="input_kms_admins"></a> [kms\_admins](#input\_kms\_admins) | https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-administrators | `list(string)` | `null` | no |
| <a name="input_kms_key"></a> [kms\_key](#input\_kms\_key) | The ID of custom KMS Key to encrypt resources. | `string` | `null` | no |
| <a name="input_kms_owners"></a> [kms\_owners](#input\_kms\_owners) | ARNs of who will be able to do all key operations/ | `list(string)` | `null` | no |
| <a name="input_kms_users"></a> [kms\_users](#input\_kms\_users) | https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-users | `list(string)` | `null` | no |
| <a name="input_lb_access_cidr_blocks"></a> [lb\_access\_cidr\_blocks](#input\_lb\_access\_cidr\_blocks) | The CIDR to from which the access Datagrok load balancer is allowed. | `string` | `"0.0.0.0/0"` | no |
| <a name="input_lb_name"></a> [lb\_name](#input\_lb\_name) | The name of Datagrok load balancer. If it is not specified, the name along with the environment will be used. | `string` | `null` | no |
| <a name="input_monitoring"></a> [monitoring](#input\_monitoring) | Monitoring object.<br>`alarms_enabled` - Specifies whether CloudWatch Alarms are enabled. We recommend to set it to true for production stand.<br>`create_sns_topic` - Specifies whether Datagrok SNS topic should be created. If it is set to false, `sns_topic_arn` is required.<br>`sns_topic_name` - The name of Datagrok SNS topic. If it is not specified, the name along with the environment will be used.<br>`sns_topic_arn` - An ARN of the custom SNS topic for CloudWatch alarms.<br>`email_alerts` - Specifies whether CloudWatch Alarms are forwarded to Email. We recommend to set it to true for production stand.<br>`email_recipients` - List of email addresses to receive CloudWatch Alarms.<br>`email_alerts_datagrok` - Specifies whether CloudWatch Alarms are forwarded to Datagrok Email. We recommend to set it to true for production stand.<br>`slack_alerts` - Specifies whether CloudWatch Alarms are forwarded to Slack. We recommend to set it to true for production stand.<br>`slack_emoji` - A custom emoji that will appear on Slack messages from CloudWatch alarms.<br>`slack_webhook_url` - The URL of Slack webhook for CloudWatch alarm notifications.<br>`slack_channel` - The name of the channel in Slack for notifications from CloudWatch alarms.<br>`slack_username` - The username that will appear on Slack messages from CloudWatch alarms. | <pre>object({<br>    alarms_enabled        = bool<br>    create_sns_topic      = bool<br>    sns_topic_arn         = optional(string)<br>    sns_topic_name        = optional(string)<br>    email_alerts          = optional(bool, true)<br>    email_recipients      = optional(list(string), [])<br>    email_alerts_datagrok = bool<br>    slack_alerts          = optional(bool, false)<br>    slack_emoji           = optional(string)<br>    slack_webhook_url     = optional(string)<br>    slack_channel         = optional(string)<br>    slack_username        = optional(string)<br>  })</pre> | <pre>{<br>  "alarms_enabled": true,<br>  "create_sns_topic": true,<br>  "email_alerts": true,<br>  "email_alerts_datagrok": true,<br>  "slack_alerts": false<br>}</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | The name for a stand. It will be used to name resources along with the environment. | `string` | n/a | yes |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | The IDs of private subnets to place resources. Required if 'vpc\_id' is specified. | `list(string)` | `[]` | no |
| <a name="input_public_key"></a> [public\_key](#input\_public\_key) | SSH Public Key to create keypair in AWS and access EC2 instance. If not set key\_pair\_name is required. | `string` | `null` | no |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | The IDs of public subnets to place resources. Required if 'vpc\_id' is specified. | `list(string)` | `[]` | no |
| <a name="input_rds_allocated_storage"></a> [rds\_allocated\_storage](#input\_rds\_allocated\_storage) | The RDS allocated storage in gibibytes. | `number` | `50` | no |
| <a name="input_rds_backup_retention_period"></a> [rds\_backup\_retention\_period](#input\_rds\_backup\_retention\_period) | The RDS backup retention period. | `number` | `3` | no |
| <a name="input_rds_dg_password"></a> [rds\_dg\_password](#input\_rds\_dg\_password) | The password for datagrok user in RDS. If it is not specified, the random password will be generated, 16 symbols long without special characters. | `string` | `null` | no |
| <a name="input_rds_instance_class"></a> [rds\_instance\_class](#input\_rds\_instance\_class) | RDS instance class. The default value is the minimum recommended class. | `string` | `"db.t3.large"` | no |
| <a name="input_rds_major_engine_version"></a> [rds\_major\_engine\_version](#input\_rds\_major\_engine\_version) | The postgres engine major version for RDS. | `string` | `"12"` | no |
| <a name="input_rds_master_password"></a> [rds\_master\_password](#input\_rds\_master\_password) | The superuser password in RDS. If it is not specified, the random password will be generated. | `string` | `null` | no |
| <a name="input_rds_master_username"></a> [rds\_master\_username](#input\_rds\_master\_username) | The superuser username name in RDS. | `string` | `"superuser"` | no |
| <a name="input_rds_max_allocated_storage"></a> [rds\_max\_allocated\_storage](#input\_rds\_max\_allocated\_storage) | The upper limit to which Amazon RDS can automatically scale the storage of the DB instance | `number` | `100` | no |
| <a name="input_rds_multi_az"></a> [rds\_multi\_az](#input\_rds\_multi\_az) | Specifies if the RDS instance is multi-AZ. We recommend to set it to true for production stand. | `bool` | `false` | no |
| <a name="input_rds_name"></a> [rds\_name](#input\_rds\_name) | The name of RDS for Datagrok. If it is not specified, the name along with the environment will be used. | `string` | `null` | no |
| <a name="input_rds_performance_insights_enabled"></a> [rds\_performance\_insights\_enabled](#input\_rds\_performance\_insights\_enabled) | Specifies whether Performance Insights for RDS are enabled. We recommend to set it to true for production stand. | `bool` | `true` | no |
| <a name="input_root_volume_throughput"></a> [root\_volume\_throughput](#input\_root\_volume\_throughput) | EC2 root volume throughput. | `number` | `null` | no |
| <a name="input_route53_enabled"></a> [route53\_enabled](#input\_route53\_enabled) | Specifies if the Route53 is used for DNS. | `bool` | `true` | no |
| <a name="input_route53_internal_zone"></a> [route53\_internal\_zone](#input\_route53\_internal\_zone) | Route53 internal hosted zone ID. If it is not set create\_route53\_internal\_zone is required to be true | `string` | `null` | no |
| <a name="input_route53_record_name"></a> [route53\_record\_name](#input\_route53\_record\_name) | This is the name of record in Route53 for Datagrok. If if is not set the name along with environment will be used. | `string` | `null` | no |
| <a name="input_s3_backup_lifecycle"></a> [s3\_backup\_lifecycle](#input\_s3\_backup\_lifecycle) | Describes how many days store s3 backup snapshot. | `number` | `14` | no |
| <a name="input_s3_backup_schedule"></a> [s3\_backup\_schedule](#input\_s3\_backup\_schedule) | Schedule for backup aws s3 bucket. By default, time is every day 3 AM | `string` | `"cron(0 3 * * ? *)"` | no |
| <a name="input_s3_name"></a> [s3\_name](#input\_s3\_name) | The name of S3 bucket for Datagrok. If it is not specified, the name along with the environment will be used. | `string` | `null` | no |
| <a name="input_s3_policy_principal"></a> [s3\_policy\_principal](#input\_s3\_policy\_principal) | List of principal ARNs which will have access to S3 bucket. By default it is limited to the root ARN. | `list(string)` | `[]` | no |
| <a name="input_service_discovery_namespace"></a> [service\_discovery\_namespace](#input\_service\_discovery\_namespace) | Service discovery namespace for FARGATE tasks. Set 'create' to 'true' to create new one. Or set 'create' to 'false' and 'id' to AWS Service Discovery Namespace ID to use the existing one. | <pre>object({<br>    create = bool<br>    id     = optional(string)<br>  })</pre> | <pre>{<br>  "create": true<br>}</pre> | no |
| <a name="input_set_admin_password"></a> [set\_admin\_password](#input\_set\_admin\_password) | Specifies whether Datagrok Admin user password should be set to custom value. We recommend to set it to true for production stand. | `bool` | `false` | no |
| <a name="input_smtp_relay_host"></a> [smtp\_relay\_host](#input\_smtp\_relay\_host) | SMTP relay host to send emails for datagrok | `string` | `null` | no |
| <a name="input_smtp_relay_password"></a> [smtp\_relay\_password](#input\_smtp\_relay\_password) | SMTP relay password to send emails for datagrok | `string` | `null` | no |
| <a name="input_smtp_relay_port"></a> [smtp\_relay\_port](#input\_smtp\_relay\_port) | SMTP relay port to send emails for datagrok | `string` | `null` | no |
| <a name="input_smtp_relay_username"></a> [smtp\_relay\_username](#input\_smtp\_relay\_username) | SMTP relay username to send emails for datagrok | `string` | `null` | no |
| <a name="input_smtp_server"></a> [smtp\_server](#input\_smtp\_server) | Specifies whether to create SMTP server | `bool` | `false` | no |
| <a name="input_sns_topic_name"></a> [sns\_topic\_name](#input\_sns\_topic\_name) | The name of Datagrok SNS topic. If it is not specified, the name along with the environment will be used. | `string` | `null` | no |
| <a name="input_subject_alternative_names"></a> [subject\_alternative\_names](#input\_subject\_alternative\_names) | List for alternative names for ACM certificate | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Key-value map of resource tags. | `map(string)` | `{}` | no |
| <a name="input_termination_protection"></a> [termination\_protection](#input\_termination\_protection) | Termination protection for the resources created by module. | `bool` | `true` | no |
| <a name="input_vpc_create"></a> [vpc\_create](#input\_vpc\_create) | Specifies if new VPC should be created. | `bool` | `true` | no |
| <a name="input_vpc_endpoint_id"></a> [vpc\_endpoint\_id](#input\_vpc\_endpoint\_id) | The ID of VPC endpoint to connect to S3 bucket. Required if 'vpc\_id' is specified. | `string` | `null` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of VPC to place resources. If it is not specified, the VPC for Datagrok will be created. | `string` | `null` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | The name of VPC to place resources. If it is not specified, the name along with the environment will be used. | `string` | `null` | no |
| <a name="input_vpc_single_nat_gateway"></a> [vpc\_single\_nat\_gateway](#input\_vpc\_single\_nat\_gateway) | Should be true if you want to provision a single shared NAT Gateway across all of your private networks. We DO NOT recommend it for production usage. | `bool` | `false` | no |
| <a name="input_vpc_subnets_count"></a> [vpc\_subnets\_count](#input\_vpc\_subnets\_count) | The count of subnets to create; one subnet per availability zone in the region. If there are fewer availability zones than the subnets count, the availability zones count will take precedence. We recommend a minimum of 3 for production usage. | `number` | `3` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_external_arn"></a> [alb\_external\_arn](#output\_alb\_external\_arn) | The ARN of the external Application Load balancer |
| <a name="output_alb_internal_arn"></a> [alb\_internal\_arn](#output\_alb\_internal\_arn) | The ARN of the external Application Load balancer |
| <a name="output_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#output\_cloudwatch\_log\_group\_arn) | The ARN of the CloudWatch Log group |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | The name of the CloudWatch Log group |
| <a name="output_database_subnet_group"></a> [database\_subnet\_group](#output\_database\_subnet\_group) | ID of database subnet group |
| <a name="output_database_subnets"></a> [database\_subnets](#output\_database\_subnets) | List of IDs of database subnets |
| <a name="output_docker_hub_secret"></a> [docker\_hub\_secret](#output\_docker\_hub\_secret) | The ARN of the Secret for Docker Hub Authorisation |
| <a name="output_domain_name"></a> [domain\_name](#output\_domain\_name) | This is the name of domain for datagrok endpoint. It is used for the external hosted zone in Route53 and to create ACM certificates. |
| <a name="output_ec2_name"></a> [ec2\_name](#output\_ec2\_name) | The EC2 instance name of a stand. |
| <a name="output_ecs_name"></a> [ecs\_name](#output\_ecs\_name) | The ECS Cluster name of a stand. |
| <a name="output_environment"></a> [environment](#output\_environment) | The environment of a stand. |
| <a name="output_full_name"></a> [full\_name](#output\_full\_name) | The full name of a stand. |
| <a name="output_lb_name"></a> [lb\_name](#output\_lb\_name) | The Load Balancer name of a stand. |
| <a name="output_log_bucket"></a> [log\_bucket](#output\_log\_bucket) | The ID of the S3 bucket for logs |
| <a name="output_name"></a> [name](#output\_name) | The name for a stand. |
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | List of IDs of private subnets |
| <a name="output_public_subnets"></a> [public\_subnets](#output\_public\_subnets) | List of IDs of public subnets |
| <a name="output_r53_record"></a> [r53\_record](#output\_r53\_record) | The Route53 record for a stand. |
| <a name="output_rds_name"></a> [rds\_name](#output\_rds\_name) | The RDS name of a stand. |
| <a name="output_route53_external_cloudwatch_log_group_arn"></a> [route53\_external\_cloudwatch\_log\_group\_arn](#output\_route53\_external\_cloudwatch\_log\_group\_arn) | The ARN of the CloudWatch Log group for External Route53 Zone |
| <a name="output_route53_external_cloudwatch_log_group_name"></a> [route53\_external\_cloudwatch\_log\_group\_name](#output\_route53\_external\_cloudwatch\_log\_group\_name) | The name of the CloudWatch Log group for External Route53 Zone |
| <a name="output_route_53_external_zone"></a> [route\_53\_external\_zone](#output\_route\_53\_external\_zone) | The ID of the Route53 public zone for Datagrok |
| <a name="output_route_53_internal_zone"></a> [route\_53\_internal\_zone](#output\_route\_53\_internal\_zone) | The ID of the Route53 internal zone for Datagrok |
| <a name="output_s3_name"></a> [s3\_name](#output\_s3\_name) | The S3 Bucket name of a stand. |
| <a name="output_service_discovery_namespace"></a> [service\_discovery\_namespace](#output\_service\_discovery\_namespace) | The ID of the CloudMap for Datagrok |
| <a name="output_sns_topic"></a> [sns\_topic](#output\_sns\_topic) | The ARN of the SNS topic from which messages will be sent |
| <a name="output_sns_topic_name"></a> [sns\_topic\_name](#output\_sns\_topic\_name) | The SNS Topic name of a stand. |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | The CIDR block of the VPC |
| <a name="output_vpc_endpoint_id"></a> [vpc\_endpoint\_id](#output\_vpc\_endpoint\_id) | The ID of the VPC Endpoint |
| <a name="output_vpc_flow_log_destination_arn"></a> [vpc\_flow\_log\_destination\_arn](#output\_vpc\_flow\_log\_destination\_arn) | The ARN of the destination for VPC Flow Logs |
| <a name="output_vpc_flow_log_id"></a> [vpc\_flow\_log\_id](#output\_vpc\_flow\_log\_id) | The ID of the Flow Log resource |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC |
| <a name="output_vpc_name"></a> [vpc\_name](#output\_vpc\_name) | The VPC name for a stand. |
<!-- END_TF_DOCS -->