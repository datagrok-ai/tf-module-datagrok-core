variable "environment" {
  description = "Environment name"
  type        = string
}

variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for ECS tasks"
  type        = list(string)
}

variable "lb_subnets" {
  description = "List of subnet IDs for load balancer"
  type        = list(string)
}

variable "docker_datagrok_container_tag" {
  description = "Docker tag for Datagrok container"
  type        = string
}

variable "acm_cert_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
  default     = null
}

variable "lb_access_cidr_blocks" {
  description = "CIDR blocks allowed to access load balancer"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

variable "iam_role_arn" {
  description = "IAM Role ARN for CloudFormation stack (should have IAMFullAccess and PowerUserAccess policies)"
  type        = string
  default     = null
}

variable "cidr" {
  description = "VPC CIDR block to allow communication inside VPC. It will be added to security group rules for ECS services."
  type        = string
  default     = "10.0.0.0/17"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+/[0-9]+$", var.cidr))
    error_message = "CIDR must be a valid IPv4 CIDR block."
  }
}

variable "data_subnet_ids" {
  description = "List of subnet IDs for data tier (RDS)"
  type        = list(string)
}

variable "nat_gateway_eip" {
  description = "NAT Gateway EIP to allow access inside network to public load balancer"
  type        = string
  default     = ""
}

variable "s3_vpc_endpoint" {
  description = "VPC Endpoint to access Datagrok S3 bucket"
  type        = string
  default     = ""
}

variable "docker_grok_connect_tag" {
  description = "Docker tag for Grok Connect container"
  type        = string
  default     = "2.5.2"
  validation {
    condition     = can(regex("^([0-9]+\\.[0-9]+\\.[0-9]+)|latest|bleeding-edge$", var.docker_grok_connect_tag))
    error_message = "Tag must be a semantic version (x.y.z), 'latest', or 'bleeding-edge'."
  }
}

variable "docker_grok_pipe_tag" {
  description = "Docker tag for Grok Pipe container"
  type        = string
  default     = "1.0.1"
  validation {
    condition     = can(regex("^([0-9]+\\.[0-9]+\\.[0-9]+)|latest|bleeding-edge$", var.docker_grok_pipe_tag))
    error_message = "Tag must be a semantic version (x.y.z), 'latest', or 'bleeding-edge'."
  }
}

variable "docker_grok_spawner_tag" {
  description = "Docker tag for Grok Spawner container"
  type        = string
  default     = "1.11.4"
  validation {
    condition     = can(regex("^([0-9]+\\.[0-9]+\\.[0-9]+)|latest|bleeding-edge$", var.docker_grok_spawner_tag))
    error_message = "Tag must be a semantic version (x.y.z), 'latest', or 'bleeding-edge'."
  }
}

variable "docker_jkg_tag" {
  description = "Docker tag for Jupyter Kernel Gateway container"
  type        = string
  default     = "1.16.2"
  validation {
    condition     = can(regex("^([0-9]+\\.[0-9]+\\.[0-9]+)|latest|bleeding-edge$", var.docker_jkg_tag))
    error_message = "Tag must be a semantic version (x.y.z), 'latest', or 'bleeding-edge'."
  }
}

variable "docker_rabbitmq_tag" {
  description = "Docker tag for RabbitMQ container"
  type        = string
  default     = "4.0.5-management"
}

variable "internet_ingress_access" {
  description = "Whether Datagrok should be available from internet"
  type        = bool
  default     = true
}

variable "lb_access_cidr_blocks_additional" {
  description = "Additional CIDR blocks allowed to access load balancer"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for cidr in var.lb_access_cidr_blocks_additional :
      can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+/[0-9]+$", cidr)) || cidr == ""
    ])
    error_message = "All entries must be valid CIDR blocks or empty strings."
  }
}

variable "gpu_required" {
  description = "Whether to provision GPU resources"
  type        = bool
  default     = false
}

variable "gpu_ami" {
  description = "AMI ID for GPU instance"
  type        = string
  default     = "/aws/service/ecs/optimized-ami/amazon-linux-2/gpu/amzn2-ami-ecs-gpu-hvm-2.0.20241017-x86_64-ebs/image_id"
}

variable "gpu_instance_type" {
  description = "Instance type for GPU instance"
  type        = string
  default     = "g4dn.xlarge"
  validation {
    condition = contains([
      "p3.2xlarge", "p3.8xlarge", "p3.16xlarge", "p3dn.24xlarge", "p5.48xlarge",
      "g3s.xlarge", "g3.4xlarge", "g3.8xlarge", "g3.16xlarge",
      "g4dn.xlarge", "g4dn.2xlarge", "g4dn.4xlarge", "g4dn.8xlarge", "g4dn.12xlarge", "g4dn.16xlarge",
      "g5.xlarge", "g5.2xlarge", "g5.4xlarge", "g5.8xlarge", "g5.16xlarge", "g5.12xlarge", "g5.24xlarge", "g5.48xlarge",
      "g6.xlarge", "g6.2xlarge", "g6.4xlarge", "g6.8xlarge", "g6.16xlarge", "g6.12xlarge", "g6.24xlarge", "g6.48xlarge", "g6.metal",
      "gr6.4xlarge", "g6e.xlarge", "g6e.2xlarge", "g6e.4xlarge", "g6e.8xlarge", "g6e.16xlarge", "g6e.12xlarge"
    ], var.gpu_instance_type)
    error_message = "GPU instance type must be a valid GPU-enabled instance type."
  }
}

variable "postfix" {
  description = "URL postfix for backward compatibility (leave blank for new installations)"
  type        = string
  default     = ""
}

