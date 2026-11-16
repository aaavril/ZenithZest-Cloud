variable "project_id" {
  type        = string
  description = "ID del proyecto de Google Cloud"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "Región única"
}

variable "env" {
  type        = string
  default     = "dev"
  description = "Nombre del entorno"
  validation {
    condition     = contains(["dev", "prod"], var.env)
    error_message = "dev o prod."
  }
}

variable "image" {
  type        = string
  description = "Imagen del job con el SHA del commit (la pasa el pipeline)"
}

variable "input_object" {
  type        = string
  default     = "opiniones.csv"
  description = "CSV que lee el job (opiniones_crisis.csv para disparar la alerta en la demo)"
}

variable "max_opinions" {
  type        = number
  default     = 200
  description = "Tope de opiniones por corrida (cada una consume 1 unidad de la API)"
  validation {
    condition     = var.max_opinions >= 1 && var.max_opinions <= 500
    error_message = "Entre 1 y 500."
  }
}

variable "secret_id" {
  type        = string
  default     = "zenithzest-webhook"
  description = "Secreto con la URL del webhook"
}

variable "schedule" {
  type        = string
  default     = "0 9 * * *"
  description = "Cron del job diario"
}

variable "scheduler_paused" {
  type        = bool
  default     = false
  description = "Pausar el disparo diario"
}

variable "alert_emails" {
  type        = list(string)
  description = "Correos del equipo para las alertas"
}

variable "negative_threshold_pct" {
  type        = number
  default     = 40
  description = "Umbral de % negativo que dispara la alerta"
}

variable "team" {
  type        = string
  default     = "viega-cuneo"
  description = "Etiqueta team"
}

variable "owner" {
  type        = string
  default     = "avril-viega"
  description = "Etiqueta owner"
}
