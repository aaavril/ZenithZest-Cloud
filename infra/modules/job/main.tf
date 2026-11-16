# Job de contenedor (Cloud Run Jobs): corre hasta terminar y escala a cero; no cobra mientras no corre.
resource "google_service_account" "job" {
  project      = var.project_id
  account_id   = "${var.name}-sa"
  display_name = "Identidad del job ${var.name}"
}

resource "google_cloud_run_v2_job" "this" {
  project             = var.project_id
  name                = var.name
  location            = var.region
  labels              = var.labels
  deletion_protection = false

  template {
    labels      = var.labels
    task_count  = 1
    parallelism = 1

    template {
      service_account = google_service_account.job.email
      max_retries     = var.max_retries
      timeout         = "${var.timeout_seconds}s"

      containers {
        image = var.image

        resources {
          limits = {
            cpu    = "1"
            memory = "512Mi"
          }
        }

        dynamic "env" {
          for_each = var.env
          content {
            name  = env.key
            value = env.value
          }
        }
      }
    }
  }
}
