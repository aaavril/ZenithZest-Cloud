variable "project_id" {
  type        = string
  description = "ID del proyecto"
}

variable "region" {
  type        = string
  description = "Región del scheduler y del job"
}

variable "job_name" {
  type        = string
  description = "Job de Cloud Run que se dispara"
}

variable "schedule" {
  type        = string
  default     = "0 9 * * *"
  description = "Expresión cron (por defecto, todos los días a las 9:00)"
}

variable "time_zone" {
  type        = string
  default     = "America/Montevideo"
  description = "Zona horaria del cron"
}

variable "paused" {
  type        = bool
  default     = false
  description = "Pausar el disparo automático (para no gastar cuota de la API fuera de la demo)"
}
