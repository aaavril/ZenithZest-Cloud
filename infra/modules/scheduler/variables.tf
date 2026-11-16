variable "project_id" {
  type        = string
  description = "ID del proyecto"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "ID de proyecto inválido."
  }
}

variable "region" {
  type        = string
  description = "Región del scheduler y del job"
  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]$", var.region))
    error_message = "Región inválida (ej. us-central1)."
  }
}

variable "job_name" {
  type        = string
  description = "Job de Cloud Run que se dispara"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{3,24}$", var.job_name))
    error_message = "Nombre de job inválido."
  }
}

variable "schedule" {
  type        = string
  default     = "0 9 * * *"
  description = "Expresión cron (por defecto, todos los días a las 9:00)"
  validation {
    condition     = length(split(" ", trimspace(var.schedule))) == 5
    error_message = "Expresión cron de 5 campos."
  }
}

variable "time_zone" {
  type        = string
  default     = "America/Montevideo"
  description = "Zona horaria del cron"
  validation {
    condition     = can(regex("^[A-Za-z_]+/[A-Za-z_/]+$", var.time_zone))
    error_message = "Zona horaria IANA (ej. America/Montevideo)."
  }
}

variable "paused" {
  type        = bool
  default     = false
  description = "Pausar el disparo automático (para no gastar cuota de la API fuera de la demo)"
}
