
resource "aws_cloudformation_stack" "datagrok" {
  name = "${var.name}-${var.environment}"

  template_url = "https://datagrok-data.s3.us-east-2.amazonaws.com/deployment/vpc-fargate-dns-basic-1.26.8.yml"

  parameters = {
    # Network configuration
    DatagrokVPC            = var.vpc_id
    CIDR                   = var.cidr
    DatagrokPrivateSubnet1 = var.subnet_ids[0]
    DatagrokPrivateSubnet2 = var.subnet_ids[1]
    DatagrokPublicSubnet1  = var.lb_subnets[0]
    DatagrokPublicSubnet2  = var.lb_subnets[1]
    DatagrokDataSubnet1    = var.data_subnet_ids[0]
    DatagrokDataSubnet2    = var.data_subnet_ids[1]
    DatagrokNatGatewayEIP  = var.nat_gateway_eip
    DatagrokS3VPCEndpoint  = var.s3_vpc_endpoint
    # Access configuration
    InternetIngressAccess = var.internet_ingress_access ? "true" : "false"
    InternetSubnetAllow   = var.lb_access_cidr_blocks[0]
    InternetSubnetAllow2  = length(var.lb_access_cidr_blocks_additional) > 0 ? var.lb_access_cidr_blocks_additional[0] : ""
    InternetSubnetAllow3  = length(var.lb_access_cidr_blocks_additional) > 1 ? var.lb_access_cidr_blocks_additional[1] : ""
    # GPU configuration
    GpuRequired     = var.gpu_required ? "true" : "false"
    GpuAMI          = var.gpu_ami
    GpuInstanceType = var.gpu_instance_type
    # Client Endpoint configuration
    DatagrokArnSSLCertificate = var.acm_cert_arn != null ? var.acm_cert_arn : ""
    # Service versions
    DatagrokVersion    = var.docker_datagrok_container_tag
    GrokConnectVersion = var.docker_grok_connect_tag
    GrokPipeVersion    = var.docker_grok_pipe_tag
    RabbitmqVersion    = var.docker_rabbitmq_tag
    GrokSpawnerVersion = var.docker_grok_spawner_tag
    JKGVersion         = var.docker_jkg_tag
    # Advanced
    Postfix = var.postfix
  }

  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM"]
  iam_role_arn = var.iam_role_arn

  tags = merge(
    var.tags,
    {
      Name        = "${var.name}-${var.environment}"
      Environment = var.environment
    }
  )
}
