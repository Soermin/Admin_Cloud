data "terraform_remote_state" "infra" {
  count = var.use_infra_remote_state ? 1 : 0

  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = var.infra_state_key
    region = var.aws_region
  }
}

locals {
  infra_outputs = try(data.terraform_remote_state.infra[0].outputs, {})

  eks_cluster_name = var.eks_cluster_name != "" ? var.eks_cluster_name : try(local.infra_outputs.eks_cluster_name, "")

  repository_urls = length(var.image_repository_urls) > 0 ? var.image_repository_urls : try(local.infra_outputs.ecr_repository_urls, {})

  image_uris = {
    farm_data_service = "${local.repository_urls["farm-data-service"]}:${var.image_tag}"
    storage_service   = "${local.repository_urls["storage-service"]}:${var.image_tag}"
    frontend          = "${local.repository_urls["frontend"]}:${var.image_tag}"
    iot_simulator     = "${local.repository_urls["iot-simulator"]}:${var.image_tag}"
  }

  rds_host                = var.rds_host != "" ? var.rds_host : try(local.infra_outputs.rds_host, "")
  rds_database_name       = var.rds_database_name != "" ? var.rds_database_name : try(local.infra_outputs.rds_database_name, "")
  rds_app_username        = var.rds_app_username != "" ? var.rds_app_username : try(local.infra_outputs.rds_app_username, "")
  reports_bucket_name     = var.reports_bucket_name != "" ? var.reports_bucket_name : try(local.infra_outputs.reports_bucket_name, "")
  farm_data_irsa_role_arn = var.farm_data_irsa_role_arn != "" ? var.farm_data_irsa_role_arn : try(local.infra_outputs.farm_data_irsa_role_arn, "")
  storage_irsa_role_arn   = var.storage_irsa_role_arn != "" ? var.storage_irsa_role_arn : try(local.infra_outputs.storage_irsa_role_arn, "")
}
