# State remoto en GCS con bloqueo nativo; el bucket se pasa con -backend-config="bucket=<TF_STATE_BUCKET>".
terraform {
  backend "gcs" {
    prefix = "zenithzest/dev"
  }
}
