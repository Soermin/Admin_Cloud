variable "name" {
  type        = string
  description = "Name prefix for VPC resources."
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name used for Kubernetes subnet discovery tags."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones used for public and private subnets."
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets."
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets."
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Whether to create NAT gateway egress for private subnets."
  default     = true
}

variable "single_nat_gateway" {
  type        = bool
  description = "Whether to create one shared NAT gateway instead of one per AZ."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
  default     = {}
}
