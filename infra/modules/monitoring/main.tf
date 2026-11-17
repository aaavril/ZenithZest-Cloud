# Observabilidad: métrica personalizada, dashboard, dos alertas y retención de logs corta.

resource "google_monitoring_metric_descriptor" "sentimiento" {
  project      = var.project_id
  type         = "custom.googleapis.com/zenithzest/sentiment_pct"
  display_name = "ZenithZest - % de opiniones por sentimiento"
  description  = "Porcentaje de opiniones positivas, negativas y neutras de la última corrida del job"
  metric_kind  = "GAUGE"
  value_type   = "DOUBLE"
  unit         = "%"

  labels {
    key         = "sentiment"
    value_type  = "STRING"
    description = "positivo | negativo | neutro"
  }
}

# Los mails son sensibles: el plan (que se publica en el PR) muestra "(sensitive value)" en vez de la dirección.
# Por eso count y no for_each: for_each no acepta valores sensibles, y la cantidad de mails no es secreta.
resource "google_monitoring_notification_channel" "email" {
  count        = nonsensitive(length(var.alert_emails))
  project      = var.project_id
  display_name = "ZenithZest alertas - integrante ${count.index + 1}"
  type         = "email"
  labels = {
    email_address = var.alert_emails[count.index]
  }
}

locals {
  canales        = google_monitoring_notification_channel.email[*].id
  filtro_metrica = "metric.type=\"${google_monitoring_metric_descriptor.sentimiento.type}\" AND resource.type=\"global\""
  filtro_fallos  = "metric.type=\"run.googleapis.com/job/completed_execution_count\" AND resource.type=\"cloud_run_job\" AND resource.label.job_name=\"${var.job_name}\" AND metric.label.result=\"failed\""
}

# Alerta de negocio: demasiadas opiniones negativas
resource "google_monitoring_alert_policy" "negativas" {
  project               = var.project_id
  display_name          = "ZenithZest - opiniones negativas > ${var.negative_threshold_pct}%"
  combiner              = "OR"
  notification_channels = local.canales
  user_labels           = var.labels

  conditions {
    display_name = "% negativo por encima del umbral"
    condition_threshold {
      filter          = "${local.filtro_metrica} AND metric.label.sentiment=\"negativo\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.negative_threshold_pct
      duration        = "0s"
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  alert_strategy {
    auto_close = "86400s"
  }

  documentation {
    mime_type = "text/markdown"
    content   = "Más del ${var.negative_threshold_pct}% de las opiniones de hoy son negativas. Revisar el reporte HTML del día en el bucket de reportes."
  }
}

# Alerta técnica: el job falló
resource "google_monitoring_alert_policy" "job_fallido" {
  project               = var.project_id
  display_name          = "ZenithZest - ejecución del job fallida"
  combiner              = "OR"
  notification_channels = local.canales
  user_labels           = var.labels

  conditions {
    display_name = "Ejecución terminada con error"
    condition_threshold {
      filter          = local.filtro_fallos
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "0s"
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_DELTA"
      }
    }
  }

  alert_strategy {
    auto_close = "86400s"
  }

  documentation {
    mime_type = "text/markdown"
    content   = "El job ${var.job_name} terminó con error. Ver los logs con severity>=ERROR en Cloud Logging."
  }
}

resource "google_monitoring_dashboard" "zenithzest" {
  project = var.project_id
  dashboard_json = jsonencode({
    displayName = "ZenithZest - sentimiento de clientes"
    mosaicLayout = {
      columns = 12
      tiles = [
        {
          width = 6, height = 4, xPos = 0, yPos = 0
          widget = {
            title = "% positivo"
            scorecard = {
              timeSeriesQuery = { timeSeriesFilter = {
                filter      = "${local.filtro_metrica} AND metric.label.sentiment=\"positivo\""
                aggregation = { alignmentPeriod = "86400s", perSeriesAligner = "ALIGN_MAX" }
              } }
            }
          }
        },
        {
          width = 6, height = 4, xPos = 6, yPos = 0
          widget = {
            title = "% negativo"
            scorecard = {
              timeSeriesQuery = { timeSeriesFilter = {
                filter      = "${local.filtro_metrica} AND metric.label.sentiment=\"negativo\""
                aggregation = { alignmentPeriod = "86400s", perSeriesAligner = "ALIGN_MAX" }
              } }
              thresholds = [{ value = var.negative_threshold_pct, color = "RED", direction = "ABOVE" }]
            }
          }
        },
        {
          width = 12, height = 5, xPos = 0, yPos = 4
          widget = {
            title = "Tendencia del sentimiento (%)"
            xyChart = {
              dataSets = [{
                plotType = "LINE"
                timeSeriesQuery = { timeSeriesFilter = {
                  filter      = local.filtro_metrica
                  aggregation = { alignmentPeriod = "3600s", perSeriesAligner = "ALIGN_MAX" }
                } }
              }]
            }
          }
        },
        {
          width = 12, height = 4, xPos = 0, yPos = 9
          widget = {
            title = "Ejecuciones del job por resultado"
            xyChart = {
              dataSets = [{
                plotType = "STACKED_BAR"
                timeSeriesQuery = { timeSeriesFilter = {
                  filter = "metric.type=\"run.googleapis.com/job/completed_execution_count\" AND resource.type=\"cloud_run_job\" AND resource.label.job_name=\"${var.job_name}\""
                  aggregation = {
                    alignmentPeriod    = "3600s"
                    perSeriesAligner   = "ALIGN_DELTA"
                    crossSeriesReducer = "REDUCE_SUM"
                    groupByFields      = ["metric.label.result"]
                  }
                } }
              }]
            }
          }
        },
      ]
    }
  })
}

# Retención de logs: 7 días (el mínimo útil; el default es 30)
resource "google_logging_project_bucket_config" "default" {
  project        = var.project_id
  location       = "global"
  bucket_id      = "_Default"
  retention_days = 7
}
