# Permisos de la cuenta del job: cada uno sobre el recurso más chico posible (ver docs/iam.md).

# Leer SOLO el bucket de entrada
resource "google_storage_bucket_iam_member" "job_lee_entrada" {
  bucket = module.storage.input_bucket
  role   = "roles/storage.objectViewer"
  member = module.job.member
}

# Crear objetos SOLO en el bucket de reportes (no puede leer, borrar ni sobrescribir)
resource "google_storage_bucket_iam_member" "job_escribe_reportes" {
  bucket = module.storage.reports_bucket
  role   = "roles/storage.objectCreator"
  member = module.job.member
}

# Escribir métricas personalizadas (no existe un rol más chico; no permite leer ni borrar)
resource "google_project_iam_member" "job_metricas" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = module.job.member
}

# Consumir la API de lenguaje facturando al proyecto
resource "google_project_iam_member" "job_api_lenguaje" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = module.job.member
}

# El acceso al secreto se da en el módulo secret (secretAccessor solo sobre ese secreto).
# La invocación del job se da en el módulo scheduler (run.invoker solo sobre ese job).
