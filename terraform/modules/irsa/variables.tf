variable "name_prefix" {
  type        = string
  description = "Name prefix for IAM roles and policies."
}

variable "oidc_issuer_url" {
  type        = string
  description = "EKS OIDC issuer URL."
}

variable "oidc_thumbprint_list" {
  type        = list(string)
  description = "Optional OIDC thumbprint list. Leave empty to derive from the issuer certificate."
  default     = []
}

variable "aws_region" {
  type        = string
  description = "AWS region."
}

variable "aws_account_id" {
  type        = string
  description = "AWS account ID."
}

variable "s3_bucket_arn" {
  type        = string
  description = "Reports S3 bucket ARN."
}

variable "rds_db_resource_id" {
  type        = string
  description = "RDS DB resource ID for rds-db:connect."
}

variable "rds_db_username" {
  type        = string
  description = "RDS IAM database username."
}

variable "farm_data_namespace" {
  type        = string
  description = "Kubernetes namespace for farm-data-service."
  default     = "farm-data"
}

variable "farm_data_service_account" {
  type        = string
  description = "Kubernetes service account for farm-data-service."
  default     = "farm-data-service"
}

variable "storage_namespace" {
  type        = string
  description = "Kubernetes namespace for storage-service."
  default     = "storage"
}

variable "storage_service_account" {
  type        = string
  description = "Kubernetes service account for storage-service."
  default     = "storage-service"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
  default     = {}
}
