output "job_name" {
  description = "Nombre del job"
  value       = google_cloud_run_v2_job.this.name
}

output "service_account_email" {
  description = "Cuenta de servicio con la que corre el job"
  value       = google_service_account.job.email
}

output "member" {
  description = "Miembro IAM de la cuenta del job"
  value       = "serviceAccount:${google_service_account.job.email}"
}
