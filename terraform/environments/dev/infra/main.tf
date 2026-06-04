module "vpc" {
  source = "../../../modules/vpc"

  name                 = local.name_prefix
  cluster_name         = local.cluster_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = local.selected_azs
  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  tags                 = local.common_tags
}

module "ecr" {
  source = "../../../modules/ecr"

  repository_names = var.ecr_repository_names
  max_image_count  = var.ecr_max_image_count
  tags             = local.common_tags
}

module "reports_bucket" {
  source = "../../../modules/s3"

  bucket_name   = local.reports_bucket_name
  force_destroy = var.reports_bucket_force_destroy
  tags          = local.common_tags
}

module "eks" {
  source = "../../../modules/eks"

  cluster_name              = local.cluster_name
  cluster_version           = var.eks_cluster_version
  vpc_id                    = module.vpc.vpc_id
  cluster_subnet_ids        = module.vpc.private_subnet_ids
  node_subnet_ids           = local.eks_node_subnet_ids
  endpoint_public_access    = var.eks_endpoint_public_access
  endpoint_private_access   = var.eks_endpoint_private_access
  public_access_cidrs       = var.eks_public_access_cidrs
  enabled_cluster_log_types = var.eks_enabled_cluster_log_types
  node_group_name           = local.node_group_name
  node_instance_types       = var.node_instance_types
  node_capacity_type        = var.node_capacity_type
  node_desired_size         = var.node_desired_size
  node_min_size             = var.node_min_size
  node_max_size             = var.node_max_size
  node_disk_size            = var.node_disk_size
  node_labels = {
    role        = "worker"
    project     = var.project
    environment = var.environment
  }
  tags = local.common_tags
}

module "rds" {
  source = "../../../modules/rds"

  identifier                 = local.rds_identifier
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.eks.node_security_group_id]
  allowed_cidr_blocks        = module.vpc.private_subnet_cidrs
  database_name              = var.rds_database_name
  master_username            = var.rds_master_username
  app_username               = var.rds_app_username
  engine_version             = var.rds_engine_version
  instance_class             = var.rds_instance_class
  backup_retention_period    = var.rds_backup_retention_period
  skip_final_snapshot        = var.rds_skip_final_snapshot
  tags                       = local.common_tags
}

module "irsa" {
  source = "../../../modules/irsa"

  name_prefix        = local.name_prefix
  oidc_issuer_url    = module.eks.oidc_issuer_url
  aws_region         = local.region
  aws_account_id     = local.account_id
  s3_bucket_arn      = module.reports_bucket.bucket_arn
  rds_db_resource_id = module.rds.resource_id
  rds_db_username    = module.rds.app_username
  tags               = local.common_tags
}

module "github_oidc" {
  source = "../../../modules/github-oidc"

  name_prefix                = local.name_prefix
  github_repository          = var.github_repository
  allowed_branches           = var.github_allowed_branches
  create_oidc_provider       = var.create_github_oidc_provider
  existing_oidc_provider_arn = var.existing_github_oidc_provider_arn
  ecr_repository_arns        = values(module.ecr.repository_arns)
  eks_cluster_name           = module.eks.cluster_name
  eks_cluster_arn            = module.eks.cluster_arn
  state_bucket_arn           = local.state_bucket_arn
  tags                       = local.common_tags
}

module "budget" {
  count  = var.budget_enabled ? 1 : 0
  source = "../../../modules/budget"

  budget_name                = "${local.name_prefix}-monthly-budget"
  limit_amount               = var.budget_limit_amount
  project_tag_value          = var.project
  subscriber_email_addresses = var.budget_subscriber_email_addresses
  tags                       = local.common_tags
}
