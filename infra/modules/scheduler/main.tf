# Programador diario: llama a la API de Cloud Run para ejecutar el job, con su propia identidad.
resource "google_service_account" "scheduler" {
  project      = var.project_id
  account_id   = "${var.job_name}-cron"
  display_name = "Scheduler que dispara ${var.job_name}"
}

# Solo puede ejecutar ESTE job (permiso a nivel del job, no del proyecto)
resource "google_cloud_run_v2_job_iam_member" "invoker" {
  project  = var.project_id
  location = var.region
  name     = var.job_name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.scheduler.email}"
}

resource "google_cloud_scheduler_job" "diario" {
  project     = var.project_id
  region      = var.region
  name        = "${var.job_name}-diario"
  description = "Ejecuta ${var.job_name} una vez por día"
  schedule    = var.schedule
  time_zone   = var.time_zone
  paused      = var.paused

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "POST"
    uri         = "https://run.googleapis.com/v2/projects/${var.project_id}/locations/${var.region}/jobs/${var.job_name}:run"

    oauth_token {
      service_account_email = google_service_account.scheduler.email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }
  }

  depends_on = [google_cloud_run_v2_job_iam_member.invoker]
}
