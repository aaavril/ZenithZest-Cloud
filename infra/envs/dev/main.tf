locals {
  name_prefix = "${var.project_id}-zz-${var.env}"
  job_name    = "zenithzest-job"
  labels = {
    project = "zenithzest"
    team    = var.team
    env     = var.env
    owner   = var.owner
  }
}

module "storage" {
  source      = "../../modules/storage"
  project_id  = var.project_id
  region      = var.region
  name_prefix = local.name_prefix
  labels      = local.labels
  input_files = {
    "opiniones.csv"        = "${path.module}/../../../data/opiniones.csv"
    "opiniones_crisis.csv" = "${path.module}/../../../data/opiniones_crisis.csv"
  }
}

module "job" {
  source     = "../../modules/job"
  project_id = var.project_id
  region     = var.region
  name       = local.job_name
  image      = var.image
  labels     = local.labels
  env = {
    PROJECT_ID     = var.project_id
    INPUT_BUCKET   = module.storage.input_bucket
    INPUT_OBJECT   = var.input_object
    REPORTS_BUCKET = module.storage.reports_bucket
    SECRET_ID      = var.secret_id
    MAX_OPINIONS   = tostring(var.max_opinions)
  }
}

module "secret" {
  source     = "../../modules/secret"
  project_id = var.project_id
  secret_id  = var.secret_id
  labels     = local.labels
  accessors  = [module.job.member]
}

module "scheduler" {
  source     = "../../modules/scheduler"
  project_id = var.project_id
  region     = var.region
  job_name   = module.job.job_name
  schedule   = var.schedule
  paused     = var.scheduler_paused
}

module "monitoring" {
  source                 = "../../modules/monitoring"
  project_id             = var.project_id
  job_name               = module.job.job_name
  alert_emails           = var.alert_emails
  negative_threshold_pct = var.negative_threshold_pct
  labels                 = local.labels
}
