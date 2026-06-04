module "k8s_app" {
  source = "../../../modules/k8s-app"

  project                 = var.project
  environment             = var.environment
  aws_region              = var.aws_region
  farm_data_irsa_role_arn = local.farm_data_irsa_role_arn
  storage_irsa_role_arn   = local.storage_irsa_role_arn
  image_uris              = local.image_uris
  rds_host                = local.rds_host
  rds_port                = var.rds_port
  rds_db_name             = local.rds_database_name
  rds_db_user             = local.rds_app_username
  s3_bucket               = local.reports_bucket_name
  iot_interval_seconds    = var.iot_interval_seconds
}
