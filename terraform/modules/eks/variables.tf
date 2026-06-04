variable "cluster_name" {
  type        = string
  description = "EKS cluster name."
}

variable "cluster_version" {
  type        = string
  description = "EKS Kubernetes version."
  default     = "1.34"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID."
}

variable "cluster_subnet_ids" {
  type        = list(string)
  description = "Subnets used by the EKS control plane."
}

variable "node_subnet_ids" {
  type        = list(string)
  description = "Subnets used by the EKS managed node group."
}

variable "endpoint_public_access" {
  type        = bool
  description = "Whether the EKS public API endpoint is enabled."
  default     = true
}

variable "endpoint_private_access" {
  type        = bool
  description = "Whether the EKS private API endpoint is enabled."
  default     = true
}

variable "public_access_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed to access the public EKS API endpoint."
  default     = ["0.0.0.0/0"]
}

variable "enabled_cluster_log_types" {
  type        = list(string)
  description = "EKS control plane log types to enable."
  default     = []
}

variable "node_group_name" {
  type        = string
  description = "EKS managed node group name."
}

variable "node_instance_types" {
  type        = list(string)
  description = "EC2 instance types for worker nodes."
  default     = ["t3.small"]
}

variable "node_capacity_type" {
  type        = string
  description = "EKS node capacity type."
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "node_capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "node_desired_size" {
  type        = number
  description = "Desired node count."
  default     = 2
}

variable "node_min_size" {
  type        = number
  description = "Minimum node count."
  default     = 1
}

variable "node_max_size" {
  type        = number
  description = "Maximum node count."
  default     = 3
}

variable "node_disk_size" {
  type        = number
  description = "Worker node root disk size in GiB."
  default     = 20
}

variable "node_labels" {
  type        = map(string)
  description = "Labels applied to worker nodes."
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
  default     = {}
}
