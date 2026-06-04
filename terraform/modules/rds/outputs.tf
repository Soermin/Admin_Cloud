output "instance_identifier" {
  description = "RDS DB instance identifier."
  value       = aws_db_instance.this.identifier
}

output "resource_id" {
  description = "RDS DB resource ID used for rds-db:connect IAM ARNs."
  value       = aws_db_instance.this.resource_id
}

output "endpoint" {
  description = "RDS endpoint with port."
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "RDS hostname."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "RDS port."
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "Database name."
  value       = aws_db_instance.this.db_name
}

output "app_username" {
  description = "Application database username expected by workloads."
  value       = var.app_username
}

output "security_group_id" {
  description = "RDS security group ID."
  value       = aws_security_group.this.id
}

output "master_user_secret_arn" {
  description = "Secrets Manager ARN for the AWS-managed master password."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
  sensitive   = true
}
