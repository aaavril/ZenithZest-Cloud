output "dashboard_id" {
  description = "ID del dashboard"
  value       = google_monitoring_dashboard.zenithzest.id
}

output "metric_type" {
  description = "Tipo de la métrica personalizada"
  value       = google_monitoring_metric_descriptor.sentimiento.type
}
