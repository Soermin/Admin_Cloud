output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_version" {
  description = "EKS Kubernetes version."
  value       = aws_eks_cluster.this.version
}

output "cluster_arn" {
  description = "EKS cluster ARN."
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded cluster CA data."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "oidc_issuer_url" {
  description = "EKS OIDC issuer URL."
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "cluster_security_group_id" {
  description = "Additional EKS cluster security group ID."
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "EKS managed node security group ID."
  value       = aws_security_group.nodes.id
}

output "node_role_arn" {
  description = "EKS managed node IAM role ARN."
  value       = aws_iam_role.nodes.arn
}
