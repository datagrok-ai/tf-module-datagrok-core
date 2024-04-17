data "aws_kms_key" "backup_vault_kms" {
  key_id = var.backup_vault_kms_key_id
}

data "aws_iam_policy" "backup_default_policy" {
  name = "AWSBackupServiceRolePolicyForBackup"
}
resource "aws_iam_role" "rds_backup_role" {
  name = "${var.backup_vault_name}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "backup.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_default_backup_policy" {
  role       = aws_iam_role.rds_backup_role.name
  policy_arn = data.aws_iam_policy.backup_default_policy.arn
}

resource "aws_backup_vault" "example" {
  name        = "${var.backup_vault_name}_vault"
  kms_key_arn = data.aws_kms_key.backup_vault_kms.arn
}