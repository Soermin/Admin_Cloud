variable "budget_name" {
  type        = string
  description = "Budget name."
}

variable "limit_amount" {
  type        = string
  description = "Monthly budget amount."
  default     = "10"
}

variable "limit_unit" {
  type        = string
  description = "Budget currency unit."
  default     = "USD"
}

variable "project_tag_value" {
  type        = string
  description = "Project tag value used for cost filtering."
}

variable "subscriber_email_addresses" {
  type        = list(string)
  description = "Email addresses for budget notifications."
  default     = []
}

variable "threshold_percent" {
  type        = number
  description = "Notification threshold percentage."
  default     = 80
}

variable "tags" {
  type        = map(string)
  description = "Tags applied where supported."
  default     = {}
}
