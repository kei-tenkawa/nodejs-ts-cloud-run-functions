terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.34.0"
    }
  }
}

locals {
  project         = "advent-calendar-2024-w"
  region          = "asia-northeast1"
  zone            = "asia-northeast1-a"
  domain          = "api.tenkawa-k.com"
  ESPv2_image_ver = "2.51.0"
}

provider "google" {
  project = "advent-calendar-2024-w"
  region  = "asia-northeast1"
}

data "google_project" "project" {
}

resource "random_id" "default" {
  byte_length = 8
}

resource "google_storage_bucket" "default" {
  name                        = "${random_id.default.hex}-gcf-source"
  location                    = "asia-northeast1"
  uniform_bucket_level_access = true
}

data "archive_file" "default" {
  type        = "zip"
  output_path = "/tmp/function-source.zip"
  source_dir  = "./dist"
}

resource "google_storage_bucket_object" "object" {
  name   = "${data.archive_file.default.output_sha256}-function-source.zip"
  bucket = google_storage_bucket.default.name
  source = data.archive_file.default.output_path
}

resource "google_cloudfunctions2_function" "default" {
  name        = "sample-crf"
  location    = "asia-northeast1"
  description = "a new function"

  build_config {
    runtime     = "nodejs20"
    entry_point = "helloGET"
    source {
      storage_source {
        bucket = google_storage_bucket.default.name
        object = google_storage_bucket_object.object.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
  }
}

resource "google_cloud_run_v2_service_iam_member" "member" {
  project  = local.project
  name     = google_cloudfunctions2_function.default.name
  location = google_cloudfunctions2_function.default.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_secret_manager_secret" "my-secret" {
  secret_id = "my-secret"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "my-secret-version" {
  secret      = google_secret_manager_secret.my-secret.id
  secret_data = file("${path.module}/my-secret.json")

  deletion_policy = "DELETE"
}

data "google_secret_manager_secret_version" "my-secret-version-latest" {
  secret  = google_secret_manager_secret.my-secret.id
  version = "latest"

  depends_on = [
    google_secret_manager_secret_version.my-secret-version
  ]
}

resource "google_secret_manager_secret_iam_member" "secretmanager-my-secret" {
  secret_id = google_secret_manager_secret.my-secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"

  condition {
    title       = "my-secret Access IAM"
    description = "my-secret へのアクセスをCloud Run functionsに付与"
    expression  = "resource.name.startsWith(\"${google_secret_manager_secret.my-secret.name}\")"
  }
}

resource "google_endpoints_service" "openapi_service" {
  service_name   = local.domain
  project        = local.project
  openapi_config = templatefile("${path.module}/openapi-functions.yml", {
    CLOUD_RUN_HOST           = local.domain
    CLOUD_RUN_FUNCTIONS_HOST = google_cloudfunctions2_function.default.service_config[0].uri
  })
}

resource "google_project_iam_member" "espv2_service_account_service_controller" {
  project = data.google_project.project.project_id
  role    = "roles/servicemanagement.serviceController"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "espv2_service_account_function_invoker" {
  project = data.google_project.project.project_id
  role    = "roles/cloudfunctions.invoker"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

resource "null_resource" "building_new_image" {
  triggers = {
    config_id          = google_endpoints_service.openapi_service.config_id
    cloud_run_hostname = google_endpoints_service.openapi_service.service_name
  }
  provisioner "local-exec" {
    command     = "chmod +x gcloud_build_image; ./gcloud_build_image -s $cloud_run_hostname -c $config_id -p ${local.project} -v ${local.ESPv2_image_ver}"
    environment = {
      config_id          = google_endpoints_service.openapi_service.config_id
      cloud_run_hostname = google_endpoints_service.openapi_service.service_name
    } 
  }

  depends_on = [
    google_endpoints_service.openapi_service
  ]
}

resource "google_cloud_run_v2_service" "gateway" {
  name          = "gateway"
  location      = local.region
  deletion_protection = false

  template { 
    containers {
      image = format(
        "gcr.io/%s/endpoints-runtime-serverless:%s-%s-%s",
        local.project,
        local.ESPv2_image_ver,
        google_endpoints_service.openapi_service.service_name,
        google_endpoints_service.openapi_service.config_id
      )
      resources {
        limits = {
          "cpu" = "1"
          "memory" = "1Gi"
        }
        cpu_idle          = true
        startup_cpu_boost = false
      }
    }
  }

  depends_on = [
    google_endpoints_service.openapi_service,
    null_resource.building_new_image
  ]
}

resource "google_cloud_run_v2_service_iam_binding" "binding" {
  project  = local.project
  location = google_cloud_run_v2_service.gateway.location
  name     = google_cloud_run_v2_service.gateway.name
  role     = "roles/run.invoker"
  members = [
    "allUsers"
  ]
}

resource "google_cloud_run_domain_mapping" "default" {
  location = local.region
  name     = local.domain

  metadata {
    namespace = local.project
  }

  spec {
    route_name = google_cloud_run_v2_service.gateway.name
  }
}

output "function_uri" {
  value = google_cloudfunctions2_function.default.service_config[0].uri
}

output "gateway_uri" {
  value = google_cloud_run_v2_service.gateway.uri
}
