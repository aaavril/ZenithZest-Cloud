terraform {
  required_version = ">= 1.6"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  # Etiquetas obligatorias en todo recurso que las admita
  default_labels = {
    project    = "zenithzest"
    team       = var.team
    env        = var.env
    owner      = var.owner
    managed_by = "terraform"
  }
}
