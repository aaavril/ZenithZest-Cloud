output "tf_state_bucket" {
  description = "Variable de GitHub TF_STATE_BUCKET"
  value       = google_storage_bucket.tfstate.name
}

output "workload_identity_provider" {
  description = "Variable de GitHub GCP_WIF_PROVIDER"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "pipeline_service_account" {
  description = "Variable de GitHub GCP_SERVICE_ACCOUNT"
  value       = google_service_account.pipeline.email
}

output "image_repository" {
  description = "Variable de GitHub IMAGE_REPO"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.app.repository_id}"
}
