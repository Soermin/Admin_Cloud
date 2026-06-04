variable "name_prefix" {
  type        = string
  description = "Name prefix for GitHub OIDC resources."
}

variable "github_repository" {
  type        = string
  description = "GitHub repository in owner/name format."
}

variable "allowed_branches" {
  type        = list(string)
  description = "Branches allowed to assume the GitHub Actions role."
  default     = ["main"]
}

variable "additional_subjects" {
  type        = list(string)
  description = "Additional GitHub OIDC subject patterns allowed to assume the role."
  default     = []
}

variable "create_oidc_provider" {
  type        = bool
  description = "Whether to create the account-level GitHub OIDC provider."
  default     = true
}

variable "existing_oidc_provider_arn" {
  type        = string
  description = "Existing GitHub OIDC provider ARN when create_oidc_provider is false."
  default     = ""
}

variable "github_oidc_thumbprints" {
  type        = list(string)
  description = "Thumbprints for token.actions.githubusercontent.com."
  default     = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

variable "ecr_repository_arns" {
  type        = list(string)
  description = "ECR repository ARNs the role can push to and pull from."
}

variable "eks_cluster_name" {
  type        = string
  description = "EKS cluster name used for deploy access."
}

variable "eks_cluster_arn" {
  type        = string
  description = "EKS cluster ARN used for DescribeCluster permissions."
}

variable "grant_eks_cluster_admin" {
  type        = bool
  description = "Whether to grant the role AmazonEKSClusterAdminPolicy through EKS access entries."
  default     = true
}

variable "state_bucket_arn" {
  type        = string
  description = "Terraform state bucket ARN for CI remote state access. Leave empty to skip."
  default     = ""
}

variable "state_key_prefix" {
  type        = string
  description = "Terraform state key prefix allowed to GitHub Actions."
  default     = "smartfarming/dev"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
  default     = {}
}
