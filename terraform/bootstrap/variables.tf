variable "aws_region" {
  type        = string
  description = "AWS region where the Terraform state bucket will be created."
  default     = "ap-southeast-1"
}

variable "project" {
  type        = string
  description = "Project tag value."
  default     = "smartfarming"
}

variable "environment" {
  type        = string
  description = "Environment tag value for the bootstrap resources."
  default     = "dev"
}

variable "owner" {
  type        = string
  description = "Owner tag value."
  default     = "tuan-sormin"
}

variable "cost_center" {
  type        = string
  description = "CostCenter tag value."
  default     = "CC-AGRI-01"
}

variable "state_bucket_name" {
  type        = string
  description = "Optional explicit state bucket name. Leave empty to use smartfarming-tf-state-<account-id>-<region>."
  default     = ""
}

variable "force_destroy" {
  type        = bool
  description = "Whether Terraform may delete a non-empty state bucket. Keep false for normal usage."
  default     = false
}
