terraform {
  required_providers {
    http = {
      source  = "hashicorp/http"
      version = "3.4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

variable "endpoint" {
  type = string
}

variable "lb_dns_name" {
  description = "Load balancer DNS name"
  type        = string
}

data "aws_route53_zone" "main" {
  name         = "datagrok.ai."
  private_zone = false
}

resource "aws_route53_record" "datagrok" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "CNAME"
  ttl     = 300
  records = [var.lb_dns_name]
}

data "http" "index" {
  url    = var.endpoint
  method = "GET"

  depends_on = [aws_route53_record.datagrok]
}

variable "domain_name" {
  description = "Domain name or DNS name of the Datagrok load balancer"
  type        = string
}
