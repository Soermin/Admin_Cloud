output "oidc_provider_arn" {
  description = "EKS OIDC provider ARN."
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "farm_data_role_arn" {
  description = "IRSA role ARN for farm-data-service."
  value       = aws_iam_role.this["farm_data"].arn
}

output "storage_role_arn" {
  description = "IRSA role ARN for storage-service."
  value       = aws_iam_role.this["storage"].arn
}

output "farm_data_policy_arn" {
  description = "RDS IAM policy ARN for farm-data-service."
  value       = aws_iam_policy.farm_data_rds.arn
}

output "storage_policy_arn" {
  description = "S3 policy ARN for storage-service."
  value       = aws_iam_policy.storage_s3.arn
}
