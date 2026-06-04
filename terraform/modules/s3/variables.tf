variable "bucket_name" {
  type        = string
  description = "S3 bucket name."
}

variable "force_destroy" {
  type        = bool
  description = "Whether Terraform may delete a non-empty bucket on destroy."
  default     = false
}

variable "noncurrent_version_expiration_days" {
  type        = number
  description = "Days before noncurrent object versions expire."
  default     = 30
}

variable "abort_multipart_days" {
  type        = number
  description = "Days before incomplete multipart uploads are aborted."
  default     = 7
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
  default     = {}
}
