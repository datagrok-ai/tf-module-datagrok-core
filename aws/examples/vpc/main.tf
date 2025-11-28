terraform {
  required_version = ">= 1.2.0"

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "name" {
  type    = string
  default = "vpc-test"
}

variable "environment" {
  type    = string
  default = "datagrok"
}

variable "domain_name" {
  type    = string
  default = "vpc-test.datagrok.ai"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.5"

  name = "${var.name}-${var.environment}"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway               = true
  enable_vpn_gateway               = false
  single_nat_gateway               = true
  create_private_nat_gateway_route = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.name}-${var.environment}"
    Environment = var.environment
  }
}

module "datagrok" {
  source = "../../"

  name        = var.name
  environment = var.environment

  # Network configuration
  vpc_id          = module.vpc.vpc_id
  cidr            = module.vpc.vpc_cidr_block
  subnet_ids      = module.vpc.private_subnets
  lb_subnets      = module.vpc.public_subnets
  data_subnet_ids = module.vpc.private_subnets
  nat_gateway_eip = module.vpc.nat_public_ips[0]
  s3_vpc_endpoint = ""

  # Access configuration
  internet_ingress_access          = true
  lb_access_cidr_blocks            = ["0.0.0.0/0"]
  lb_access_cidr_blocks_additional = []

  # SSL/DNS configuration
  acm_cert_arn = "arn:aws:acm:us-east-1:766822877060:certificate/ed377c38-a9ba-4b78-88b4-838203cf5f7b"

  # Service versions
  docker_datagrok_container_tag = "1.26.5"
  docker_grok_connect_tag       = "2.5.2"
  docker_grok_pipe_tag          = "1.0.1"
  docker_rabbitmq_tag           = "4.0.5-management"
  docker_grok_spawner_tag       = "1.11.4"
  docker_jkg_tag                = "1.16.2"

  # GPU configuration
  gpu_required      = false
  gpu_ami           = "/aws/service/ecs/optimized-ami/amazon-linux-2/gpu/amzn2-ami-ecs-gpu-hvm-2.0.20241017-x86_64-ebs/image_id"
  gpu_instance_type = "g4dn.xlarge"

  postfix = ""

  # IAM
  iam_role_arn = "arn:aws:iam::766822877060:role/CloudFormationExecutionRole"

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }

  #db_snapshot_identifier = "arn:aws:rds:us-east-1:766822877060:snapshot:mds-snapshot"

  depends_on = [module.vpc]
}

resource "aws_route53_record" "datagrok" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "CNAME"
  ttl     = 300
  records = [module.datagrok.lb_dns_name]

  depends_on = [module.datagrok]
}

data "aws_route53_zone" "main" {
  name         = "datagrok.ai."
  private_zone = false
}

output "admin_password" {
  value = module.datagrok.admin_password
}
