variable "project_id" {
  type        = string
  description = "ID del proyecto"
}

variable "job_name" {
  type        = string
  description = "Job de Cloud Run que se monitorea"
}

variable "alert_emails" {
  type        = list(string)
  description = "Correos que reciben las alertas"
}

variable "negative_threshold_pct" {
  type        = number
  default     = 40
  description = "Umbral de % de opiniones negativas que dispara la alerta"
  validation {
    condition     = var.negative_threshold_pct > 0 && var.negative_threshold_pct < 100
    error_message = "Entre 0 y 100."
  }
}

variable "labels" {
  type        = map(string)
  description = "Etiquetas obligatorias"
}
