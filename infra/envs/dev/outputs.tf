output "input_bucket" {
  description = "Bucket de entrada"
  value       = module.storage.input_bucket
}

output "reports_bucket" {
  description = "Bucket de reportes"
  value       = module.storage.reports_bucket
}

output "job_name" {
  description = "Job de Cloud Run"
  value       = module.job.job_name
}

output "job_service_account" {
  description = "Cuenta de servicio del job"
  value       = module.job.service_account_email
}

output "scheduler_job" {
  description = "Programador diario"
  value       = module.scheduler.scheduler_job
}

output "secret_id" {
  description = "Secreto del webhook (cargar el valor por CLI)"
  value       = module.secret.secret_id
}

output "dashboard_url" {
  description = "Dashboard en la consola"
  value       = "https://console.cloud.google.com/monitoring/dashboards/builder/${element(split("/", module.monitoring.dashboard_id), 3)}?project=${var.project_id}"
}
