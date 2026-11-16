terraform {
  required_version = ">= 1.6"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
  # El state del bootstrap queda local (terraform.tfstate, ignorado por git):
  # es el huevo y la gallina del bucket remoto. Guardarlo en un lugar seguro.
}

provider "google" {
  project               = var.project_id
  region                = var.region
  user_project_override = true # la API de presupuestos lo necesita
  billing_project       = var.project_id
}
