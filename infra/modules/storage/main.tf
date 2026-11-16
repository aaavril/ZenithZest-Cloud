# Dos buckets privados: "entrada" (opiniones.csv) y "reportes" (salida del job).
locals {
  buckets = {
    entrada  = { ttl_dias = var.input_ttl_days }
    reportes = { ttl_dias = var.reports_ttl_days }
  }
}

resource "google_storage_bucket" "this" {
  #checkov:skip=CKV_GCP_78:Datos de prueba regenerables con TTL; el versionado solo sumaría costo
  #checkov:skip=CKV_GCP_62:Logs de acceso descartados por costo en un entorno de pruebas; buckets privados con prevención de acceso público
  for_each                    = local.buckets
  name                        = "${var.name_prefix}-${each.key}"
  project                     = var.project_id
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = true # datos de prueba: el destroy tiene que quedar limpio
  labels                      = var.labels

  versioning {
    enabled = false
  }

  # TTL de los datos de prueba
  lifecycle_rule {
    condition {
      age = each.value.ttl_dias
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket_object" "opiniones" {
  for_each = var.input_files
  bucket   = google_storage_bucket.this["entrada"].name
  name     = each.key
  source   = each.value
}
