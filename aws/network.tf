module "vpc" {
  count   = var.vpc_create ? 1 : 0
  source  = "registry.terraform.io/terraform-aws-modules/vpc/aws"
  version = "~> 3.14.2"

  name = local.vpc_name

  azs  = slice(data.aws_availability_zones.available.names, 0, var.vpc_subnets_count)
  cidr = var.cidr

  public_subnets = [
  for zone in slice(data.aws_availability_zones.available.names, 0, var.vpc_subnets_count) :
  cidrsubnet(var.cidr, 7, index(data.aws_availability_zones.available.names, zone) + 1)
  ]
  private_subnets = [
  for zone in slice(data.aws_availability_zones.available.names, 0, var.vpc_subnets_count) :
  cidrsubnet(var.cidr, 7, index(data.aws_availability_zones.available.names, zone) + 11)
  ]
  database_subnets = [
  for zone in slice(data.aws_availability_zones.available.names, 0, var.vpc_subnets_count) :
  cidrsubnet(var.cidr, 7, index(data.aws_availability_zones.available.names, zone) + 21)
  ]

  enable_ipv6                            = false
  create_igw                             = true
  enable_nat_gateway                     = true
  single_nat_gateway                     = var.vpc_single_nat_gateway
  one_nat_gateway_per_az                 = false
  map_public_ip_on_launch                = true
  create_database_subnet_group           = true
  create_database_subnet_route_table     = false
  create_database_internet_gateway_route = false
  create_database_nat_gateway_route      = false
  enable_dns_hostnames                   = true
  enable_dns_support                     = true

  enable_flow_log                                 = var.enable_flow_logs
  flow_log_destination_type                       = "cloud-watch-logs"
  flow_log_cloudwatch_log_group_name_prefix       = var.flow_log_cloudwatch_log_group_name_prefix
  flow_log_file_format                            = "plain-text"
  flow_log_log_format                             = var.flow_log_log_format
  flow_log_cloudwatch_log_group_retention_in_days = 7
  create_flow_log_cloudwatch_log_group            = true
  create_flow_log_cloudwatch_iam_role             = true
  flow_log_max_aggregation_interval               = 60

  tags = local.tags
}
data "aws_iam_policy_document" "vpc_endpoint_policy" {
  count = var.vpc_create ? 1 : 0
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    resources = [
      module.s3_bucket.s3_bucket_arn,
      "${module.s3_bucket.s3_bucket_arn}/*",
      "arn:aws:s3:::amazonlinux.${data.aws_region.current.name}.amazonaws.com/*",
      "arn:aws:s3:::amazonlinux-2-repos-${data.aws_region.current.name}/*"
    ]
  }
}
module "vpc_endpoint" {
  count   = var.vpc_create ? 1 : 0
  source  = "registry.terraform.io/terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 3.14.2"

  vpc_id = module.vpc[0].vpc_id

  endpoints = {
    s3 = {
      # interface endpoint
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc[0].private_route_table_ids
      policy          = data.aws_iam_policy_document.vpc_endpoint_policy[0].json
      tags            = { Name = "datagrok-s3-vpc-endpoint" }
    }
  }

  tags = local.tags
}
