output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks."
  value       = [for subnet in aws_subnet.public : subnet.cidr_block]
}

output "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks."
  value       = [for subnet in aws_subnet.private : subnet.cidr_block]
}
