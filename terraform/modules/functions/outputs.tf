output "function_uri" {
  value = google_cloudfunctions2_function.sample.service_config[0].uri
}
