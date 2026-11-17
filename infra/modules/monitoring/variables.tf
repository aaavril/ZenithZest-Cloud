variable "project_id" {
  type        = string
  description = "ID del proyecto"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "ID de proyecto inválido."
  }
}

variable "job_name" {
  type        = string
  description = "Job de Cloud Run que se monitorea"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{3,24}$", var.job_name))
    error_message = "Nombre de job inválido."
  }
}

variable "alert_emails" {
  type        = list(string)
  description = "Correos que reciben las alertas"
  sensitive   = true # no se imprimen en el plan publicado en el PR
  validation {
    condition     = length(var.alert_emails) > 0 && alltrue([for e in var.alert_emails : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", e))])
    error_message = "Al menos un correo, todos con formato válido."
  }
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
  validation {
    condition     = alltrue([for k in ["project", "team", "env", "owner"] : contains(keys(var.labels), k)])
    error_message = "Faltan etiquetas obligatorias: project, team, env, owner."
  }
}
