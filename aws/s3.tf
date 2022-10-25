resource "random_pet" "this" {
  count  = var.enable_bucket_logging && !try(length(var.log_bucket) > 0, false) ? 1 : 0
  length = 2
}
module "log_bucket" {
  create_bucket = var.enable_bucket_logging && !try(length(var.log_bucket) > 0, false)
  source        = "registry.terraform.io/terraform-aws-modules/s3-bucket/aws"
  version       = "~> 3.3.0"

  bucket        = "logs-${var.name}-${var.environment}-${try(random_pet.this[0].id, "")}"
  acl           = "log-delivery-write"
  force_destroy = true

  attach_elb_log_delivery_policy        = true
  attach_lb_log_delivery_policy         = true
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  lifecycle_rule = [
    {
      id      = "expiration_rule"
      enabled = true
      expiration = {
        days = 7
      }
    }
  ]
  tags = local.tags
}
data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid = "1"
    principals {
      identifiers = ["*"]
      type        = "*"
    }
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    effect = "Deny"
    resources = [
      module.s3_bucket.s3_bucket_arn,
      "${module.s3_bucket.s3_bucket_arn}/*"
    ]
    condition {
      test     = "StringNotEquals"
      values   = [try(length(var.vpc_id) > 0, false) ? var.vpc_endpoint_id : module.vpc_endpoint[0].endpoints["s3"].id]
      variable = "aws:SourceVpce"
    }
  }
}
module "s3_bucket" {
  source  = "registry.terraform.io/terraform-aws-modules/s3-bucket/aws"
  version = "~>3.3.0"

  bucket = local.s3_name

  force_destroy       = !var.termination_protection
  acceleration_status = "Suspended"

  # Bucket policies
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true
  attach_policy                         = true
  policy                                = data.aws_iam_policy_document.bucket_policy.json

  # S3 bucket-level Public Access Block configuration
  acl                     = "private"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # S3 Bucket Ownership Controls
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls
  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"
  expected_bucket_owner    = data.aws_caller_identity.current.account_id
  request_payer            = "BucketOwner"

  logging = var.enable_bucket_logging ? {
    target_bucket = try(length(var.log_bucket) > 0, false) ? var.log_bucket : module.log_bucket.s3_bucket_id
    target_prefix = "s3/"
  } : {}

  versioning = {
    status     = true
    mfa_delete = false
  }

  #  server_side_encryption_configuration = {
  #    rule = {
  #      apply_server_side_encryption_by_default = {
  #        kms_master_key_id = var.custom_kms_key ? (try(length(var.kms_key) > 0, false) ? var.kms_key : module.kms[0].key_arn) : null
  #        sse_algorithm     = "aws:kms"
  #      }
  #    }
  #  }

  tags = local.tags
}
