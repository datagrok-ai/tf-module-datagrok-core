resource "random_pet" "this" {
  count  = var.bucket_logging.enabled && var.bucket_logging.create_log_bucket ? 1 : 0
  length = 2
}
module "log_bucket" {
  create_bucket = var.bucket_logging.enabled && var.bucket_logging.create_log_bucket
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
    sid = "0"
    principals {
      type = "AWS"
      identifiers = compact(concat([
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ], var.s3_policy_principal))
    }
    actions = ["s3:*"]
    effect  = "Allow"
    resources = [
      module.s3_bucket.s3_bucket_arn,
      "${module.s3_bucket.s3_bucket_arn}/*"
    ]
  }
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
      values   = [try(module.vpc_endpoint[0].endpoints["s3"].id, var.vpc_endpoint_id)]
      variable = "aws:SourceVpce"
    }
    condition {
      test = "StringNotEquals"
      values = compact(concat([
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ], var.s3_policy_principal))
      variable = "aws:PrincipalArn"
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

  logging = var.bucket_logging.enabled ? {
    target_bucket = var.bucket_logging.create_log_bucket ? module.log_bucket.s3_bucket_id : var.bucket_logging.log_bucket
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
# aws S3 backup //////////////////////
resource "aws_backup_vault" "s3_backup_vault" {
  name = "${var.name}-${var.environment}-s3-backup-vault"
}

resource "aws_iam_role" "s3_backup_role" {
  name                = "${var.name}-${var.environment}-s3-backup-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "s3_backup" {
  name        = "${var.name}-${var.environment}-backup-s3-policy"
  description = "policy for backup ${module.s3_bucket.s3_bucket_id} s3 bucket"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl",
          "s3:GetObject",
          "s3:ListBucketMultipartUploads",
          "s3:*",
          "backup:CreateBackupPlan",
          "backup:CreateBackupSelection",
          "backup:CreateBackup",
          "backup:StartBackupJob",
          "backup:ListBackupPlans",
          "backup:ListBackupSelections",
          "backup:ListBackupVaults",
          "cloudwatch:GetMetricData"
        ]
        Resource = [
          module.s3_bucket.s3_bucket_arn,
          "${module.s3_bucket.s3_bucket_arn}/*",
          "*"
        ]
      }
    ]
  })
}
# Attach an IAM policy to the backup role that allows  performing AWS Backup jobs
resource "aws_iam_role_policy_attachment" "backup_policy_attachment" {
  policy_arn = aws_iam_policy.s3_backup.arn
  role       = aws_iam_role.s3_backup_role.name
}
resource "aws_iam_role_policy_attachment" "backup_service_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Backup"
  role       = aws_iam_role.s3_backup_role.name
}
resource "aws_backup_plan" "s3_backup_plan" {
  name = "${var.name}-${var.environment}-s3-backup-plan"

  rule {
    rule_name         = "Daily-S3-backups-rule"
    target_vault_name = aws_backup_vault.s3_backup_vault.name
    schedule          = var.s3_backup_schedule

    lifecycle {
      delete_after = "${var.s3_backup_lifecycle}"
    }

    enable_continuous_backup = false


  }
  tags = local.tags
}
resource "aws_backup_selection" "s3_bucket_backup_selection" {
  iam_role_arn = aws_iam_role.s3_backup_role.arn
  name         = "${var.name}-${var.environment}-s3-bucket-backup-selection"
  plan_id      = aws_backup_plan.s3_backup_plan.id

  resources = [
    module.s3_bucket.s3_bucket_arn
  ]
}
