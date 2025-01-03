# Cloud Storage バケット (Cloud Functions ソースコード置き場)
resource "google_storage_bucket" "functions_resource" {
  name                        = "${var.random_id_hex}-gcf-source"
  location                    = var.region
  uniform_bucket_level_access = true
}

# デプロイ用のソースを ZIP 化
data "archive_file" "default" {
  type        = "zip"
  output_path = "/tmp/function-source.zip"
  source_dir  = var.dist_dir
}

# ZIP ファイルを GCS へアップロード
resource "google_storage_bucket_object" "object" {
  name   = "${data.archive_file.default.output_sha256}-function-source.zip"
  bucket = google_storage_bucket.functions_resource.name
  source = data.archive_file.default.output_path
}

# Cloud Functions (2nd gen)
resource "google_cloudfunctions2_function" "sample" {
  name        = "sample-crf"
  location    = var.region
  description = "a new function"

  build_config {
    runtime     = "nodejs20"
    entry_point = "helloGET"
    source {
      storage_source {
        bucket = google_storage_bucket.functions_resource.name
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

# Cloud Functions を呼び出すための IAM 設定
resource "google_cloud_run_v2_service_iam_member" "invoker" {
  project  = var.project
  name     = google_cloudfunctions2_function.sample.name
  location = google_cloudfunctions2_function.sample.location
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.service_account_email}"
}
