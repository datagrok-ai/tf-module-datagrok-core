provider "aws" {
  region = "us-east-1"
}

variables {
  name        = "prosper-point"
  environment = "test"
  domain_name = "prosper-point-test.datagrok.ai"
}

run "setup_tests" {
  module {
    source = "./tests/setup"
  }

  variables {
    name        = var.name
    environment = var.environment
  }
}

run "create_datagrok_app" {
  command = apply

  module {
    source = "./"
  }

  variables {
    name        = var.name
    environment = var.environment

    # Network configuration
    vpc_id          = run.setup_tests.vpc_id
    cidr            = run.setup_tests.vpc_cidr_block
    subnet_ids      = run.setup_tests.private_subnets
    lb_subnets      = run.setup_tests.public_subnets
    data_subnet_ids = run.setup_tests.private_subnets
    nat_gateway_eip = run.setup_tests.nat_public_ips[0]
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
  }

  assert {
    condition     = output.admin_password != null && output.admin_password != ""
    error_message = "Admin password was not generated"
  }
}

run "datagrok_is_running" {
  command = plan

  module {
    source = "./tests/final"
  }

  variables {
    endpoint    = "https://${run.create_datagrok_app.lb_dns_name}"
    domain_name = var.domain_name
    lb_dns_name = run.create_datagrok_app.lb_dns_name
  }
}
