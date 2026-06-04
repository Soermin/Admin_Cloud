variable "repository_names" {
  type        = list(string)
  description = "ECR repository names to create."
}

variable "image_tag_mutability" {
  type        = string
  description = "Image tag mutability for repositories."
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "max_image_count" {
  type        = number
  description = "Maximum number of images retained per repository."
  default     = 30
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
  default     = {}
}
