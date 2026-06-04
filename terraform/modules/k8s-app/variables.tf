variable "project" {
  type        = string
  description = "Project label value."
}

variable "environment" {
  type        = string
  description = "Environment label value."
}

variable "aws_region" {
  type        = string
  description = "AWS region passed to workloads."
}

variable "farm_data_namespace" {
  type        = string
  description = "Namespace for farm-data workloads."
  default     = "farm-data"
}

variable "storage_namespace" {
  type        = string
  description = "Namespace for storage workloads."
  default     = "storage"
}

variable "frontend_namespace" {
  type        = string
  description = "Namespace for frontend workloads."
  default     = "frontend"
}

variable "farm_data_irsa_role_arn" {
  type        = string
  description = "IRSA role ARN for farm-data-service."
}

variable "storage_irsa_role_arn" {
  type        = string
  description = "IRSA role ARN for storage-service."
}

variable "image_uris" {
  type = object({
    farm_data_service = string
    storage_service   = string
    frontend          = string
    iot_simulator     = string
  })
  description = "Fully qualified image URIs including tag."
}

variable "image_pull_policy" {
  type        = string
  description = "Kubernetes image pull policy."
  default     = "IfNotPresent"
}

variable "rds_host" {
  type        = string
  description = "RDS PostgreSQL hostname."
}

variable "rds_port" {
  type        = string
  description = "RDS PostgreSQL port."
  default     = "5432"
}

variable "rds_db_name" {
  type        = string
  description = "RDS database name."
}

variable "rds_db_user" {
  type        = string
  description = "RDS IAM database user."
}

variable "s3_bucket" {
  type        = string
  description = "Reports S3 bucket name."
}

variable "db_init_retries" {
  type        = string
  description = "DB initialization retry count."
  default     = "60"
}

variable "db_init_delay_seconds" {
  type        = string
  description = "DB initialization delay in seconds."
  default     = "2"
}

variable "s3_init_retries" {
  type        = string
  description = "S3 initialization retry count."
  default     = "60"
}

variable "s3_init_delay_seconds" {
  type        = string
  description = "S3 initialization delay in seconds."
  default     = "2"
}

variable "crop_days_since_planting" {
  type        = string
  description = "Default crop days since planting."
  default     = "10"
}

variable "crop_expected_harvest_days" {
  type        = string
  description = "Default expected harvest days."
  default     = "60"
}

variable "crop_target_energy_kwh_per_day" {
  type        = string
  description = "Default daily target energy in kWh."
  default     = "100"
}

variable "iot_interval_seconds" {
  type        = string
  description = "IoT simulator send interval."
  default     = "60"
}

variable "farm_data_replicas" {
  type        = number
  description = "Initial farm-data-service replicas."
  default     = 2
}

variable "storage_replicas" {
  type        = number
  description = "Initial storage-service replicas."
  default     = 2
}

variable "frontend_replicas" {
  type        = number
  description = "Initial frontend replicas."
  default     = 2
}

variable "hpa_min_replicas" {
  type        = number
  description = "Minimum HPA replicas."
  default     = 2
}

variable "hpa_max_replicas" {
  type        = number
  description = "Maximum HPA replicas."
  default     = 4
}

variable "hpa_cpu_average_utilization" {
  type        = number
  description = "HPA CPU average utilization target."
  default     = 60
}
