data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  name_prefix = var.name_prefix != "" ? var.name_prefix : "${var.project}-tf-${var.environment}"

  selected_azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  public_subnet_cidrs = length(var.public_subnet_cidrs) > 0 ? var.public_subnet_cidrs : [
    for index in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, index)
  ]

  private_subnet_cidrs = length(var.private_subnet_cidrs) > 0 ? var.private_subnet_cidrs : [
    for index in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, index + 10)
  ]

  cluster_name        = local.name_prefix
  node_group_name     = "${local.name_prefix}-ng"
  reports_bucket_name = var.reports_bucket_name != "" ? var.reports_bucket_name : "${var.project}-tf-reports-${local.account_id}-${local.region}"
  rds_identifier      = var.rds_identifier != "" ? var.rds_identifier : "${var.project}-tf-postgres-${var.environment}"
  state_bucket_name   = var.terraform_state_bucket_name != "" ? var.terraform_state_bucket_name : "${var.project}-tf-state-${local.account_id}-${local.region}"
  state_bucket_arn    = "arn:aws:s3:::${local.state_bucket_name}"

  eks_node_subnet_ids = var.node_subnet_type == "private" ? module.vpc.private_subnet_ids : module.vpc.public_subnet_ids

  common_tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "terraform"
    CostCenter  = var.cost_center
    Service     = "shared"
  }
}
