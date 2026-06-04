variable "identifier" {
  type        = string
  description = "RDS DB instance identifier."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the RDS security group."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the DB subnet group."
}

variable "allowed_security_group_ids" {
  type        = list(string)
  description = "Security group IDs allowed to connect to PostgreSQL."
  default     = []
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed to connect to PostgreSQL."
  default     = []
}

variable "database_name" {
  type        = string
  description = "Initial database name."
  default     = "farming"
}

variable "master_username" {
  type        = string
  description = "RDS master username. Password is managed by AWS Secrets Manager."
  default     = "postgres"
}

variable "app_username" {
  type        = string
  description = "Application database user that will use RDS IAM authentication."
  default     = "farm_app_user"
}

variable "engine_version" {
  type        = string
  description = "PostgreSQL engine version. Use a supported 16.x version in your region."
  default     = "16.4"
}

variable "instance_class" {
  type        = string
  description = "RDS instance class."
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  type        = number
  description = "Allocated storage in GiB."
  default     = 20
}

variable "backup_retention_period" {
  type        = number
  description = "Automated backup retention in days."
  default     = 7
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Whether to skip the final snapshot during destroy."
  default     = true
}

variable "deletion_protection" {
  type        = bool
  description = "Whether deletion protection is enabled."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
  default     = {}
}
