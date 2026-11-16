output "input_bucket" {
  description = "Nombre del bucket de entrada"
  value       = google_storage_bucket.this["entrada"].name
}

output "reports_bucket" {
  description = "Nombre del bucket de reportes"
  value       = google_storage_bucket.this["reportes"].name
}
