# OpenAPI 仕様を使って Endpoints をデプロイ
resource "google_endpoints_service" "openapi_service" {
  service_name   = var.domain
  project        = var.project
  openapi_config = templatefile("${path.module}/openapi-functions.yml", {
    CLOUD_RUN_HOST           = var.domain
    CLOUD_RUN_FUNCTIONS_HOST = var.function_uri
  })
}

# ESPv2 のデプロイに必要な IAM ロール付与
resource "google_project_iam_member" "ESPv2_service_account_service_controller" {
  project = var.project
  role    = "roles/servicemanagement.serviceController"
  member  = "serviceAccount:${var.service_account_number}-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "ESPv2_service_account_function_invoker" {
  project = var.project
  role    = "roles/cloudfunctions.invoker"
  member  = "serviceAccount:${var.service_account_number}-compute@developer.gserviceaccount.com"
}

# ESPv2 イメージをビルドするためのローカル実行例
resource "null_resource" "building_new_image" {
  triggers = {
    config_id          = google_endpoints_service.openapi_service.config_id
    cloud_run_hostname = google_endpoints_service.openapi_service.service_name
  }
  provisioner "local-exec" {
    command     = "chmod +x gcloud_build_image; ./gcloud_build_image -s $cloud_run_hostname -c $config_id -p ${var.project} -v ${var.ESPv2_image_ver}"
    environment = {
      config_id          = google_endpoints_service.openapi_service.config_id
      cloud_run_hostname = google_endpoints_service.openapi_service.service_name
    }
  }

  depends_on = [
    google_endpoints_service.openapi_service
  ]
}
