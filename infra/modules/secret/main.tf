# El secreto se crea VACÍO: el valor (URL del webhook) se carga por CLI y nunca pasa por Terraform ni por Git.
#   printf '%s' "https://discord.com/api/webhooks/..." | gcloud secrets versions add <secret_id> --data-file=-
resource "google_secret_manager_secret" "this" {
  project   = var.project_id
  secret_id = var.secret_id
  labels    = var.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_iam_member" "accessor" {
  for_each  = toset(var.accessors)
  project   = var.project_id
  secret_id = google_secret_manager_secret.this.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = each.value
}
