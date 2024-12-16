terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.34.0"
    }
  }
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
    # service_account_email = google_service_account.cloud-run-functions.email
  }
}

resource "google_cloud_run_service_iam_member" "member" {
  location = google_cloudfunctions2_function.default.location
  service  = google_cloudfunctions2_function.default.name
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
   title       = "my-secret iam"
   description = "my-secret へのアクセス許可のみ許されているIAM"
   expression  = "resource.name.startsWith(\"${google_secret_manager_secret.my-secret.name}\")"
  }
}

output "function_uri" {
  value = google_cloudfunctions2_function.default.service_config[0].uri
}
