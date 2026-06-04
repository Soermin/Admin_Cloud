locals {
  base_labels = {
    "app.kubernetes.io/part-of" = var.project
    "environment"               = var.environment
  }

  farm_data_labels = merge(local.base_labels, { app = "farm-data-service" })
  storage_labels   = merge(local.base_labels, { app = "storage-service" })
  frontend_labels  = merge(local.base_labels, { app = "frontend" })
  iot_labels       = merge(local.base_labels, { app = "iot-simulator" })
}

resource "kubernetes_namespace_v1" "farm_data" {
  metadata {
    name   = var.farm_data_namespace
    labels = local.base_labels
  }
}

resource "kubernetes_namespace_v1" "storage" {
  metadata {
    name   = var.storage_namespace
    labels = local.base_labels
  }
}

resource "kubernetes_namespace_v1" "frontend" {
  metadata {
    name   = var.frontend_namespace
    labels = local.base_labels
  }
}

resource "kubernetes_service_account_v1" "farm_data" {
  metadata {
    name      = "farm-data-service"
    namespace = kubernetes_namespace_v1.farm_data.metadata[0].name
    labels    = local.farm_data_labels
    annotations = {
      "eks.amazonaws.com/role-arn" = var.farm_data_irsa_role_arn
    }
  }
}

resource "kubernetes_service_account_v1" "storage" {
  metadata {
    name      = "storage-service"
    namespace = kubernetes_namespace_v1.storage.metadata[0].name
    labels    = local.storage_labels
    annotations = {
      "eks.amazonaws.com/role-arn" = var.storage_irsa_role_arn
    }
  }
}

resource "kubernetes_service_account_v1" "frontend" {
  metadata {
    name      = "frontend"
    namespace = kubernetes_namespace_v1.frontend.metadata[0].name
    labels    = local.frontend_labels
  }
}

resource "kubernetes_service_account_v1" "iot_simulator" {
  metadata {
    name      = "iot-simulator"
    namespace = kubernetes_namespace_v1.farm_data.metadata[0].name
    labels    = local.iot_labels
  }
}

resource "kubernetes_config_map_v1" "farm_data" {
  metadata {
    name      = "farm-data-config"
    namespace = kubernetes_namespace_v1.farm_data.metadata[0].name
    labels    = local.farm_data_labels
  }

  data = {
    AWS_REGION                     = var.aws_region
    RDS_HOST                       = var.rds_host
    RDS_PORT                       = var.rds_port
    RDS_DB_NAME                    = var.rds_db_name
    RDS_DB_USER                    = var.rds_db_user
    DB_INIT_RETRIES                = var.db_init_retries
    DB_INIT_DELAY_SECONDS          = var.db_init_delay_seconds
    CROP_DAYS_SINCE_PLANTING       = var.crop_days_since_planting
    CROP_EXPECTED_HARVEST_DAYS     = var.crop_expected_harvest_days
    CROP_TARGET_ENERGY_KWH_PER_DAY = var.crop_target_energy_kwh_per_day
  }
}

resource "kubernetes_config_map_v1" "storage" {
  metadata {
    name      = "storage-config"
    namespace = kubernetes_namespace_v1.storage.metadata[0].name
    labels    = local.storage_labels
  }

  data = {
    AWS_REGION            = var.aws_region
    S3_BUCKET             = var.s3_bucket
    S3_INIT_RETRIES       = var.s3_init_retries
    S3_INIT_DELAY_SECONDS = var.s3_init_delay_seconds
  }
}

resource "kubernetes_config_map_v1" "iot_simulator" {
  metadata {
    name      = "iot-simulator-config"
    namespace = kubernetes_namespace_v1.farm_data.metadata[0].name
    labels    = local.iot_labels
  }

  data = {
    FARM_DATA_URL    = "http://farm-data-service.${var.farm_data_namespace}.svc.cluster.local:8000"
    INTERVAL_SECONDS = var.iot_interval_seconds
  }
}

resource "kubernetes_deployment_v1" "farm_data" {
  metadata {
    name      = "farm-data-service"
    namespace = kubernetes_namespace_v1.farm_data.metadata[0].name
    labels    = local.farm_data_labels
  }

  spec {
    replicas               = var.farm_data_replicas
    revision_history_limit = 2

    selector {
      match_labels = {
        app = "farm-data-service"
      }
    }

    template {
      metadata {
        labels = local.farm_data_labels
      }

      spec {
        service_account_name = kubernetes_service_account_v1.farm_data.metadata[0].name

        container {
          name              = "farm-data-service"
          image             = var.image_uris.farm_data_service
          image_pull_policy = var.image_pull_policy

          port {
            name           = "http"
            container_port = 8000
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.farm_data.metadata[0].name
            }
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "300m"
              memory = "384Mi"
            }
          }

          startup_probe {
            http_get {
              path = "/health"
              port = 8000
            }
            period_seconds    = 5
            timeout_seconds   = 3
            failure_threshold = 60
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8000
            }
            period_seconds    = 10
            timeout_seconds   = 3
            failure_threshold = 6
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8000
            }
            period_seconds    = 20
            timeout_seconds   = 5
            failure_threshold = 3
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment_v1" "storage" {
  metadata {
    name      = "storage-service"
    namespace = kubernetes_namespace_v1.storage.metadata[0].name
    labels    = local.storage_labels
  }

  spec {
    replicas               = var.storage_replicas
    revision_history_limit = 2

    selector {
      match_labels = {
        app = "storage-service"
      }
    }

    template {
      metadata {
        labels = local.storage_labels
      }

      spec {
        service_account_name = kubernetes_service_account_v1.storage.metadata[0].name

        container {
          name              = "storage-service"
          image             = var.image_uris.storage_service
          image_pull_policy = var.image_pull_policy

          port {
            name           = "http"
            container_port = 8000
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.storage.metadata[0].name
            }
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }

          startup_probe {
            http_get {
              path = "/health"
              port = 8000
            }
            period_seconds    = 5
            timeout_seconds   = 3
            failure_threshold = 60
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8000
            }
            period_seconds    = 10
            timeout_seconds   = 3
            failure_threshold = 6
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8000
            }
            period_seconds    = 20
            timeout_seconds   = 5
            failure_threshold = 3
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment_v1" "frontend" {
  metadata {
    name      = "frontend"
    namespace = kubernetes_namespace_v1.frontend.metadata[0].name
    labels    = local.frontend_labels
  }

  spec {
    replicas               = var.frontend_replicas
    revision_history_limit = 2

    selector {
      match_labels = {
        app = "frontend"
      }
    }

    template {
      metadata {
        labels = local.frontend_labels
      }

      spec {
        service_account_name = kubernetes_service_account_v1.frontend.metadata[0].name

        container {
          name              = "frontend"
          image             = var.image_uris.frontend
          image_pull_policy = var.image_pull_policy

          port {
            name           = "http"
            container_port = 80
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "150m"
              memory = "128Mi"
            }
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            period_seconds    = 10
            timeout_seconds   = 3
            failure_threshold = 6
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            period_seconds    = 20
            timeout_seconds   = 5
            failure_threshold = 3
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment_v1" "iot_simulator" {
  metadata {
    name      = "iot-simulator"
    namespace = kubernetes_namespace_v1.farm_data.metadata[0].name
    labels    = local.iot_labels
  }

  spec {
    replicas               = 1
    revision_history_limit = 2

    selector {
      match_labels = {
        app = "iot-simulator"
      }
    }

    template {
      metadata {
        labels = local.iot_labels
      }

      spec {
        service_account_name = kubernetes_service_account_v1.iot_simulator.metadata[0].name

        container {
          name              = "iot-simulator"
          image             = var.image_uris.iot_simulator
          image_pull_policy = var.image_pull_policy

          port {
            name           = "http"
            container_port = 8000
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.iot_simulator.metadata[0].name
            }
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "150m"
              memory = "128Mi"
            }
          }

          readiness_probe {
            exec {
              command = [
                "python",
                "-c",
                "import os, urllib.request; urllib.request.urlopen(os.environ['FARM_DATA_URL'] + '/health', timeout=2)"
              ]
            }
            initial_delay_seconds = 15
            period_seconds        = 20
            timeout_seconds       = 5
            failure_threshold     = 6
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "farm_data" {
  metadata {
    name      = "farm-data-service"
    namespace = kubernetes_namespace_v1.farm_data.metadata[0].name
    labels    = local.farm_data_labels
  }

  spec {
    type     = "ClusterIP"
    selector = { app = "farm-data-service" }

    port {
      name        = "http"
      port        = 8000
      target_port = "http"
    }
  }
}

resource "kubernetes_service_v1" "storage" {
  metadata {
    name      = "storage-service"
    namespace = kubernetes_namespace_v1.storage.metadata[0].name
    labels    = local.storage_labels
  }

  spec {
    type     = "ClusterIP"
    selector = { app = "storage-service" }

    port {
      name        = "http"
      port        = 8000
      target_port = "http"
    }
  }
}

resource "kubernetes_service_v1" "frontend" {
  metadata {
    name      = "frontend"
    namespace = kubernetes_namespace_v1.frontend.metadata[0].name
    labels    = local.frontend_labels
  }

  spec {
    type     = "ClusterIP"
    selector = { app = "frontend" }

    port {
      name        = "http"
      port        = 80
      target_port = "http"
    }
  }
}

resource "kubernetes_service_v1" "iot_simulator" {
  metadata {
    name      = "iot-simulator"
    namespace = kubernetes_namespace_v1.farm_data.metadata[0].name
    labels    = local.iot_labels
  }

  spec {
    type     = "ClusterIP"
    selector = { app = "iot-simulator" }

    port {
      name        = "http"
      port        = 8000
      target_port = "http"
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "farm_data" {
  metadata {
    name      = "farm-data-service-hpa"
    namespace = kubernetes_namespace_v1.farm_data.metadata[0].name
    labels    = local.farm_data_labels
  }

  spec {
    min_replicas = var.hpa_min_replicas
    max_replicas = var.hpa_max_replicas

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment_v1.farm_data.metadata[0].name
    }

    metric {
      type = "Resource"

      resource {
        name = "cpu"

        target {
          type                = "Utilization"
          average_utilization = var.hpa_cpu_average_utilization
        }
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "storage" {
  metadata {
    name      = "storage-service-hpa"
    namespace = kubernetes_namespace_v1.storage.metadata[0].name
    labels    = local.storage_labels
  }

  spec {
    min_replicas = var.hpa_min_replicas
    max_replicas = var.hpa_max_replicas

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment_v1.storage.metadata[0].name
    }

    metric {
      type = "Resource"

      resource {
        name = "cpu"

        target {
          type                = "Utilization"
          average_utilization = var.hpa_cpu_average_utilization
        }
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "frontend" {
  metadata {
    name      = "frontend-hpa"
    namespace = kubernetes_namespace_v1.frontend.metadata[0].name
    labels    = local.frontend_labels
  }

  spec {
    min_replicas = var.hpa_min_replicas
    max_replicas = var.hpa_max_replicas

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment_v1.frontend.metadata[0].name
    }

    metric {
      type = "Resource"

      resource {
        name = "cpu"

        target {
          type                = "Utilization"
          average_utilization = var.hpa_cpu_average_utilization
        }
      }
    }
  }
}
