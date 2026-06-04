variable "aws_region" {
  type        = string
  description = "AWS region for the dev environment."
  default     = "ap-southeast-1"
}

variable "project" {
  type        = string
  description = "Project name."
  default     = "smartfarming"
}

variable "environment" {
  type        = string
  description = "Environment name."
  default     = "dev"
}

variable "name_prefix" {
  type        = string
  description = "Resource name prefix. Leave empty to use <project>-tf-<environment>."
  default     = "smartfarming-tf-dev"
}

variable "owner" {
  type        = string
  description = "Owner tag."
  default     = "tuan-sormin"
}

variable "cost_center" {
  type        = string
  description = "CostCenter tag."
  default     = "CC-AGRI-01"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block."
  default     = "10.42.0.0/16"
}

variable "az_count" {
  type        = number
  description = "Number of availability zones to use."
  default     = 2
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Optional explicit public subnet CIDR blocks."
  default     = []
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Optional explicit private subnet CIDR blocks."
  default     = []
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Create NAT gateway for private subnet egress."
  default     = true
}

variable "single_nat_gateway" {
  type        = bool
  description = "Use one shared NAT gateway instead of one per AZ."
  default     = true
}

variable "node_subnet_type" {
  type        = string
  description = "Subnet type for EKS managed nodes. Use public when NAT is disabled."
  default     = "private"

  validation {
    condition     = contains(["private", "public"], var.node_subnet_type)
    error_message = "node_subnet_type must be private or public."
  }

  validation {
    condition     = var.enable_nat_gateway || var.node_subnet_type == "public"
    error_message = "When enable_nat_gateway is false, node_subnet_type must be public so EKS nodes can pull images and reach AWS APIs."
  }
}

variable "eks_cluster_version" {
  type        = string
  description = "EKS Kubernetes version. Use a version in standard support for this dev rebuild."
  default     = "1.34"
}

variable "eks_endpoint_public_access" {
  type        = bool
  description = "Enable public EKS API endpoint."
  default     = true
}

variable "eks_endpoint_private_access" {
  type        = bool
  description = "Enable private EKS API endpoint."
  default     = true
}

variable "eks_public_access_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to reach the public EKS API endpoint."
  default     = ["0.0.0.0/0"]
}

variable "eks_enabled_cluster_log_types" {
  type        = list(string)
  description = "EKS control plane logs to enable."
  default     = []
}

variable "node_instance_types" {
  type        = list(string)
  description = "EKS node instance types."
  default     = ["t3.small"]
}

variable "node_capacity_type" {
  type        = string
  description = "EKS node capacity type."
  default     = "ON_DEMAND"
}

variable "node_desired_size" {
  type        = number
  description = "Desired EKS node count."
  default     = 2
}

variable "node_min_size" {
  type        = number
  description = "Minimum EKS node count."
  default     = 1
}

variable "node_max_size" {
  type        = number
  description = "Maximum EKS node count."
  default     = 3
}

variable "node_disk_size" {
  type        = number
  description = "EKS node disk size in GiB."
  default     = 20
}

variable "ecr_repository_names" {
  type        = list(string)
  description = "ECR repositories for SmartFarming services."
  default = [
    "farm-data-service",
    "storage-service",
    "frontend",
    "iot-simulator"
  ]
}

variable "ecr_max_image_count" {
  type        = number
  description = "Maximum number of ECR images to keep per repository."
  default     = 30
}

variable "reports_bucket_name" {
  type        = string
  description = "Optional explicit reports bucket name."
  default     = ""
}

variable "reports_bucket_force_destroy" {
  type        = bool
  description = "Allow Terraform destroy to delete a non-empty reports bucket."
  default     = false
}

variable "rds_identifier" {
  type        = string
  description = "Optional explicit RDS identifier."
  default     = ""
}

variable "rds_engine_version" {
  type        = string
  description = "PostgreSQL 16.x engine version supported in the target region."
  default     = "16.4"
}

variable "rds_instance_class" {
  type        = string
  description = "RDS instance class."
  default     = "db.t3.micro"
}

variable "rds_database_name" {
  type        = string
  description = "RDS database name."
  default     = "farming"
}

variable "rds_master_username" {
  type        = string
  description = "RDS master username."
  default     = "postgres"
}

variable "rds_app_username" {
  type        = string
  description = "Application database user for RDS IAM auth."
  default     = "farm_app_user"
}

variable "rds_backup_retention_period" {
  type        = number
  description = "RDS backup retention in days."
  default     = 7
}

variable "rds_skip_final_snapshot" {
  type        = bool
  description = "Skip final RDS snapshot on destroy."
  default     = true
}

variable "github_repository" {
  type        = string
  description = "GitHub repository allowed to assume the deploy role, in owner/name format."
  default     = "Soermin/Admin_Cloud"
}

variable "github_allowed_branches" {
  type        = list(string)
  description = "Branches allowed to assume the GitHub Actions role."
  default     = ["main"]
}

variable "create_github_oidc_provider" {
  type        = bool
  description = "Create the account-level GitHub OIDC provider. Set false if it already exists."
  default     = true
}

variable "existing_github_oidc_provider_arn" {
  type        = string
  description = "Existing GitHub OIDC provider ARN when create_github_oidc_provider is false."
  default     = ""
}

variable "terraform_state_bucket_name" {
  type        = string
  description = "Terraform state bucket name for CI access. Leave empty to use smartfarming-tf-state-<account-id>-<region>."
  default     = ""
}

variable "budget_enabled" {
  type        = bool
  description = "Whether to create an AWS Budget."
  default     = true
}

variable "budget_limit_amount" {
  type        = string
  description = "Monthly budget amount."
  default     = "10"
}

variable "budget_subscriber_email_addresses" {
  type        = list(string)
  description = "Budget notification email addresses."
  default     = []
}
