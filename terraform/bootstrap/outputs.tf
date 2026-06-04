output "account_id" {
  description = "AWS account ID used for naming."
  value       = local.account_id
}

output "state_bucket_name" {
  description = "S3 bucket name for Terraform remote state."
  value       = aws_s3_bucket.terraform_state.bucket
}

output "infra_backend_config" {
  description = "Backend config values for the dev infra root module."
  value = {
    bucket       = aws_s3_bucket.terraform_state.bucket
    key          = "smartfarming/dev/infra/terraform.tfstate"
    region       = var.aws_region
    encrypt      = true
    use_lockfile = true
  }
}

output "workloads_backend_config" {
  description = "Backend config values for the dev workloads root module."
  value = {
    bucket       = aws_s3_bucket.terraform_state.bucket
    key          = "smartfarming/dev/workloads/terraform.tfstate"
    region       = var.aws_region
    encrypt      = true
    use_lockfile = true
  }
}
