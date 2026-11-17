# Bootstrap: se aplica UNA vez, a mano, con tu usuario (gcloud auth application-default login).
# Crea lo que el pipeline necesita para existir: APIs, bucket del state, registro de imágenes,
# federación OIDC con GitHub, cuenta de servicio del pipeline y alerta de presupuesto.

locals {
  labels = {
    project = "zenithzest"
    team    = var.team
    env     = "shared"
    owner   = var.owner
  }
  apis = [
    "run.googleapis.com", "cloudscheduler.googleapis.com", "language.googleapis.com",
    "secretmanager.googleapis.com", "monitoring.googleapis.com", "logging.googleapis.com",
    "artifactregistry.googleapis.com", "storage.googleapis.com", "iam.googleapis.com",
    "iamcredentials.googleapis.com", "sts.googleapis.com", "cloudresourcemanager.googleapis.com",
    "billingbudgets.googleapis.com", "serviceusage.googleapis.com",
  ]
  # Roles del pipeline sobre el proyecto: lo justo para aplicar infra/envs/dev (ver docs/iam.md)
  roles_pipeline = [
    "roles/run.admin",
    "roles/storage.admin",
    "roles/cloudscheduler.admin",
    "roles/secretmanager.admin",
    "roles/monitoring.editor",
    "roles/logging.configWriter",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountUser",
    "roles/resourcemanager.projectIamAdmin",
  ]
}

resource "google_project_service" "apis" {
  for_each           = toset(local.apis)
  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# --- State remoto (GCS tiene bloqueo nativo) ---
resource "google_storage_bucket" "tfstate" {
  #checkov:skip=CKV_GCP_62:Logs de acceso del bucket del state descartados por costo; el acceso queda en Cloud Audit Logs (Admin Activity) y el bucket tiene versionado
  name                        = "${var.project_id}-tfstate"
  project                     = var.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false
  labels                      = local.labels

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 10
    }
    action {
      type = "Delete"
    }
  }
}

# --- Registro de imágenes ---
resource "google_artifact_registry_repository" "app" {
  #checkov:skip=CKV_GCP_84:Cifrado por defecto con claves de Google; CMEK/CSEK suma costo de KMS y la imagen no tiene datos sensibles
  project       = var.project_id
  location      = var.region
  repository_id = "zenithzest"
  format        = "DOCKER"
  description   = "Imagenes del job de ZenithZest"
  labels        = local.labels

  cleanup_policies {
    id     = "conservar-ultimas-5"
    action = "KEEP"
    most_recent_versions {
      keep_count = 5
    }
  }
  cleanup_policies {
    id     = "borrar-viejas"
    action = "DELETE"
    condition {
      older_than = "604800s"
    }
  }

  depends_on = [google_project_service.apis]
}

# --- Identidad del pipeline: OIDC de GitHub, sin claves ---
resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = "github"
  display_name              = "GitHub Actions"
  depends_on                = [google_project_service.apis]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  #checkov:skip=CKV_GCP_125:Restringe por assertion.repository (recomendación de Google); la regla solo reconoce condiciones sobre assertion.sub
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-oidc"
  display_name                       = "GitHub OIDC"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }
  # Solo tokens emitidos para ESTE repositorio pueden canjearse
  attribute_condition = "assertion.repository == \"${var.github_repo}\""
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "pipeline" {
  project      = var.project_id
  account_id   = "zenithzest-pipeline"
  display_name = "Pipeline de GitHub Actions (ZenithZest)"
}

resource "google_service_account_iam_member" "pipeline_wif" {
  service_account_id = google_service_account.pipeline.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repo}"
}

resource "google_project_iam_member" "pipeline" {
  #checkov:skip=CKV_GCP_49:El pipeline crea las cuentas del job y del scheduler y las asigna a sus recursos; solo puede usarlo este repositorio (condición OIDC)
  #checkov:skip=CKV_GCP_41:Ídem: serviceAccountUser es necesario para desplegar el job con su cuenta; mitigado por la condición de repositorio en la federación
  for_each = toset(local.roles_pipeline)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.pipeline.email}"
}

resource "google_artifact_registry_repository_iam_member" "pipeline_push" {
  project    = var.project_id
  location   = google_artifact_registry_repository.app.location
  repository = google_artifact_registry_repository.app.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.pipeline.email}"
}

# --- Presupuesto: aviso al 50, 80 y 100 % a todo el equipo ---
resource "google_monitoring_notification_channel" "equipo" {
  for_each     = toset(var.team_emails)
  project      = var.project_id
  display_name = "Presupuesto - ${each.value}"
  type         = "email"
  labels = {
    email_address = each.value
  }
  depends_on = [google_project_service.apis]
}

data "google_project" "this" {
  project_id = var.project_id
}

resource "google_billing_budget" "mensual" {
  count           = var.billing_account == "" ? 0 : 1
  billing_account = var.billing_account
  display_name    = "zenithzest-presupuesto"

  budget_filter {
    projects = ["projects/${data.google_project.this.number}"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.budget_usd)
    }
  }

  dynamic "threshold_rules" {
    for_each = [0.5, 0.8, 1.0]
    content {
      threshold_percent = threshold_rules.value
    }
  }

  all_updates_rule {
    monitoring_notification_channels = [for c in google_monitoring_notification_channel.equipo : c.id]
    disable_default_iam_recipients   = false
  }
}
