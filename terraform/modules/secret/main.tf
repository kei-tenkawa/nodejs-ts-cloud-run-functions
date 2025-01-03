# シークレット resource
resource "google_secret_manager_secret" "my_secret" {
  secret_id = "my-secret"

  replication {
    auto {}
  }
}

# シークレットのバージョン resource
resource "google_secret_manager_secret_version" "my_secret_version" {
  secret      = google_secret_manager_secret.my_secret.id
  secret_data = file("${path.module}/my-secret.json")

  deletion_policy = "DELETE"
}

# 最新バージョンを取得するデータソース (依存関係のために置いている例)
data "google_secret_manager_secret_version" "my_secret_version_latest" {
  secret  = google_secret_manager_secret.my_secret.id
  version = "latest"

  depends_on = [
    google_secret_manager_secret_version.my_secret_version
  ]
}

# シークレットにアクセス可能な IAM
resource "google_secret_manager_secret_iam_member" "secretmanager_my_secret" {
  secret_id = google_secret_manager_secret.my_secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.service_account_email}"

  condition {
    title       = "my-secret Access IAM"
    description = "my-secret へのアクセスをCloud Run functionsに付与"
    expression  = "resource.name.startsWith(\"${google_secret_manager_secret.my_secret.name}\")"
  }
}
