output "namespaces" {
  description = "Namespaces managed by this module."
  value = {
    farm_data = kubernetes_namespace_v1.farm_data.metadata[0].name
    storage   = kubernetes_namespace_v1.storage.metadata[0].name
    frontend  = kubernetes_namespace_v1.frontend.metadata[0].name
  }
}

output "service_accounts" {
  description = "Service accounts managed by this module."
  value = {
    farm_data     = kubernetes_service_account_v1.farm_data.metadata[0].name
    storage       = kubernetes_service_account_v1.storage.metadata[0].name
    frontend      = kubernetes_service_account_v1.frontend.metadata[0].name
    iot_simulator = kubernetes_service_account_v1.iot_simulator.metadata[0].name
  }
}

output "services" {
  description = "ClusterIP services managed by this module."
  value = {
    farm_data     = kubernetes_service_v1.farm_data.metadata[0].name
    storage       = kubernetes_service_v1.storage.metadata[0].name
    frontend      = kubernetes_service_v1.frontend.metadata[0].name
    iot_simulator = kubernetes_service_v1.iot_simulator.metadata[0].name
  }
}
