resource "google_cloud_scheduler_job" "scheduler" {
  name             = "functions-scheduler"
  description      = "7:00/13:00/17:00で定期処理を実行する"
  schedule         = "0 7,13,17 * * *"
  time_zone        = "Asia/Tokyo"
  region           = var.region
  attempt_deadline = "180s"
  
  http_target {
    http_method = "GET"
    uri         = var.function_uri
    oidc_token {
      service_account_email = var.service_account_email
      audience              = var.function_uri
    }
  }
}
