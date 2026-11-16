# State remoto en GCS (bloqueo nativo). El bucket se pasa al iniciar:
#   terraform init -backend-config="bucket=<TF_STATE_BUCKET>"
terraform {
  backend "gcs" {
    prefix = "zenithzest/dev"
  }
}
