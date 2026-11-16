output "scheduler_job" {
  description = "Nombre del job de Cloud Scheduler"
  value       = google_cloud_scheduler_job.diario.name
}

output "service_account_email" {
  description = "Cuenta de servicio del scheduler"
  value       = google_service_account.scheduler.email
}
