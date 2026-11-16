output "secret_id" {
  description = "ID corto del secreto"
  value       = google_secret_manager_secret.this.secret_id
}
