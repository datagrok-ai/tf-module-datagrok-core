# Datagrok AWS CloudFormation Module

This Terraform module acts as a frontend for the Datagrok CloudFormation template, providing a Terraform-native interface for deployment.

## Usage

```hcl
module "datagrok" {
  source = "./aws"

  environment = "production"
  name        = "datagrok"
  vpc_id      = "vpc-xxxxx"
  subnet_ids  = ["subnet-xxxxx", "subnet-yyyyy"]
  lb_subnets  = ["subnet-xxxxx", "subnet-yyyyy"]
  
  docker_datagrok_container_tag = "latest"
  domain_name                   = "datagrok.example.com"
  acm_cert_arn                  = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxx"
  
  desired_count = 2
  
  tags = {
    Project = "Datagrok"
    ManagedBy = "Terraform"
  }
}
```

## Requirements

- Terraform >= 1.0
- AWS Provider ~> 5.0
- CloudFormation template file at `../aws`

## Features

- **CloudFormation Integration**: Deploys using the existing CloudFormation template
- **Terraform State Management**: Stack lifecycle managed through Terraform
- **Variable Mapping**: All CloudFormation parameters exposed as Terraform variables
- **Output Extraction**: CloudFormation outputs exposed as Terraform outputs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| environment | Environment name | string | - | yes |
| name | Name prefix for resources | string | - | yes |
| vpc_id | VPC ID | string | - | yes |
| subnet_ids | Subnet IDs for ECS tasks | list(string) | - | yes |
| lb_subnets | Subnet IDs for load balancer | list(string) | - | yes |
| docker_datagrok_container_tag | Docker tag | string | - | yes |
| domain_name | Domain name | string | - | yes |
| acm_cert_arn | ACM certificate ARN | string | null | no |
| cpu | ECS task CPU units | number | 2048 | no |
| memory | ECS task memory (MiB) | number | 4096 | no |
| desired_count | Desired task count | number | 1 | no |

## Outputs

All CloudFormation stack outputs are exposed through this module. See `outputs.tf` for the complete list.

## Notes

- The module expects the CloudFormation template to be located at `../aws` (one level up from the module directory)
- IAM capabilities are automatically granted to the CloudFormation stack
- Stack updates follow CloudFormation change sets and update policies
