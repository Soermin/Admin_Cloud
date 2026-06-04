output "oidc_provider_arn" {
  description = "GitHub OIDC provider ARN."
  value       = local.provider_arn
}

output "role_arn" {
  description = "GitHub Actions IAM role ARN."
  value       = aws_iam_role.github_actions.arn
}

output "policy_arn" {
  description = "GitHub Actions IAM policy ARN."
  value       = aws_iam_policy.github_actions.arn
}
