# ESPv2 コンテナを Cloud Run (v2) で起動するゲートウェイ
resource "google_cloud_run_v2_service" "gateway" {
  name                = "gateway"
  location            = var.region
  deletion_protection = false

  template {
    containers {
      image = format(
        "gcr.io/%s/endpoints-runtime-serverless:%s-%s-%s",
        var.project,
        var.ESPv2_image_ver,
        var.domain,
        var.config_id
      )
      resources {
        limits = {
          "cpu"    = "1"
          "memory" = "1Gi"
        }
        cpu_idle          = true
        startup_cpu_boost = false
      }
    }
  }
}

# Cloud Run への匿名アクセス (Invoker) 付与
resource "google_cloud_run_v2_service_iam_binding" "binding" {
  project  = var.project
  location = google_cloud_run_v2_service.gateway.location
  name     = google_cloud_run_v2_service.gateway.name
  role     = "roles/run.invoker"
  members  = [
    "allUsers"
  ]
}

# 独自ドメインを Cloud Run に紐付け
resource "google_cloud_run_domain_mapping" "default" {
  location = var.region
  name     = var.domain

  metadata {
    namespace = var.project
  }

  spec {
    route_name = google_cloud_run_v2_service.gateway.name
  }
}
