data "aws_kms_key" "backup_vault_kms" {
  key_id = var.backup_vault_kms_key_id
}

data "aws_iam_policy" "backup_default_policy" {
    name = "AWSBackupServiceRolePolicyForBackup"
}
