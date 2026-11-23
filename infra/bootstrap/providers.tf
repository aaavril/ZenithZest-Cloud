terraform {
  required_version = ">= 1.6"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
  # State local a propósito: este módulo crea el bucket remoto (el huevo y la gallina).
}

provider "google" {
  project               = var.project_id
  region                = var.region
  user_project_override = true # la API de presupuestos lo necesita
  billing_project       = var.project_id
}
