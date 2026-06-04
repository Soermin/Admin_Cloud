output "account_id" {
  description = "AWS account ID."
  value       = local.account_id
}

output "aws_region" {
  description = "AWS region."
  value       = local.region
}

output "name_prefix" {
  description = "Resource name prefix."
  value       = local.name_prefix
}

output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "eks_cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "eks_cluster_version" {
  description = "EKS Kubernetes version."
  value       = module.eks.cluster_version
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint."
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "EKS cluster CA data."
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "ecr_repository_urls" {
  description = "ECR repository URLs."
  value       = module.ecr.repository_urls
}

output "reports_bucket_name" {
  description = "Reports S3 bucket name."
  value       = module.reports_bucket.bucket_name
}

output "rds_endpoint" {
  description = "RDS endpoint with port."
  value       = module.rds.endpoint
}

output "rds_host" {
  description = "RDS hostname."
  value       = module.rds.address
}

output "rds_port" {
  description = "RDS port."
  value       = tostring(module.rds.port)
}

output "rds_database_name" {
  description = "RDS database name."
  value       = module.rds.database_name
}

output "rds_app_username" {
  description = "RDS IAM app username."
  value       = module.rds.app_username
}

output "rds_master_user_secret_arn" {
  description = "AWS-managed master user secret ARN."
  value       = module.rds.master_user_secret_arn
  sensitive   = true
}

output "farm_data_irsa_role_arn" {
  description = "IRSA role ARN for farm-data-service."
  value       = module.irsa.farm_data_role_arn
}

output "storage_irsa_role_arn" {
  description = "IRSA role ARN for storage-service."
  value       = module.irsa.storage_role_arn
}

output "github_actions_role_arn" {
  description = "GitHub Actions deploy role ARN."
  value       = module.github_oidc.role_arn
}

output "budget_name" {
  description = "Budget name, if enabled."
  value       = try(module.budget[0].budget_name, null)
}
