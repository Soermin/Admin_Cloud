variable "aws_region" {
  type        = string
  description = "AWS region."
  default     = "ap-southeast-1"
}

variable "use_infra_remote_state" {
  type        = bool
  description = "Read infra outputs from Terraform remote state."
  default     = true
}

variable "state_bucket" {
  type        = string
  description = "Terraform state bucket used to read infra outputs."
  default     = ""
}

variable "infra_state_key" {
  type        = string
  description = "S3 key for infra Terraform state."
  default     = "smartfarming/dev/infra/terraform.tfstate"
}

variable "eks_cluster_name" {
  type        = string
  description = "EKS cluster name when not using remote state."
  default     = ""
}

variable "project" {
  type        = string
  description = "Project label value."
  default     = "smartfarming"
}

variable "environment" {
  type        = string
  description = "Environment label value."
  default     = "dev"
}

variable "image_tag" {
  type        = string
  description = "Image tag for all SmartFarming services. Prefer a commit SHA in CI."
  default     = "latest"
}

variable "image_repository_urls" {
  type        = map(string)
  description = "Optional ECR repository URLs keyed by repository name."
  default     = {}
}

variable "rds_host" {
  type        = string
  description = "RDS hostname when not using remote state."
  default     = ""
}

variable "rds_port" {
  type        = string
  description = "RDS port."
  default     = "5432"
}

variable "rds_database_name" {
  type        = string
  description = "RDS database name when not using remote state."
  default     = ""
}

variable "rds_app_username" {
  type        = string
  description = "RDS app username when not using remote state."
  default     = ""
}

variable "reports_bucket_name" {
  type        = string
  description = "Reports S3 bucket name when not using remote state."
  default     = ""
}

variable "farm_data_irsa_role_arn" {
  type        = string
  description = "Farm data IRSA role ARN when not using remote state."
  default     = ""
}

variable "storage_irsa_role_arn" {
  type        = string
  description = "Storage IRSA role ARN when not using remote state."
  default     = ""
}

variable "iot_interval_seconds" {
  type        = string
  description = "IoT simulator interval in seconds."
  default     = "60"
}
