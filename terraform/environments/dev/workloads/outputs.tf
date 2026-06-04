output "namespaces" {
  description = "Managed namespaces."
  value       = module.k8s_app.namespaces
}

output "service_accounts" {
  description = "Managed service accounts."
  value       = module.k8s_app.service_accounts
}

output "services" {
  description = "Managed ClusterIP services."
  value       = module.k8s_app.services
}

output "image_uris" {
  description = "Image URIs deployed by this workload layer."
  value       = local.image_uris
}
