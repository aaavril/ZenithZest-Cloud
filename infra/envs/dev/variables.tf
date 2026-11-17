variable "project_id" {
  type        = string
  description = "ID del proyecto de Google Cloud"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "ID de proyecto inválido: 6 a 30 caracteres, minúsculas, números y guiones."
  }
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "Región única"
  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]$", var.region))
    error_message = "Región inválida (ej. us-central1)."
  }
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
  validation {
    condition     = can(regex("^[a-z0-9.-]+-docker\\.pkg\\.dev/.+:.+$", var.image)) && !endswith(var.image, ":latest")
    error_message = "Debe ser una imagen de Artifact Registry con tag explícito (nunca latest)."
  }
}

variable "input_object" {
  type        = string
  default     = "opiniones.csv"
  description = "CSV que lee el job (opiniones_crisis.csv para disparar la alerta en la demo)"
  validation {
    condition     = endswith(var.input_object, ".csv")
    error_message = "Tiene que ser un archivo .csv."
  }
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
  validation {
    condition     = can(regex("^[A-Za-z0-9_-]{1,255}$", var.secret_id))
    error_message = "Solo letras, números, guiones y guiones bajos."
  }
}

variable "schedule" {
  type        = string
  default     = "0 9 * * *"
  description = "Cron del job diario"
  validation {
    condition     = length(split(" ", trimspace(var.schedule))) == 5
    error_message = "Expresión cron de 5 campos (ej. \"0 9 * * *\")."
  }
}

variable "scheduler_paused" {
  type        = bool
  default     = false
  description = "Pausar el disparo diario"
}

variable "alert_emails" {
  type        = list(string)
  description = "Correos del equipo para las alertas"
  sensitive   = true # no se imprimen en el plan publicado en el PR
  validation {
    condition     = length(var.alert_emails) > 0 && alltrue([for e in var.alert_emails : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", e))])
    error_message = "Al menos un correo, todos con formato válido."
  }
}

variable "negative_threshold_pct" {
  type        = number
  default     = 40
  description = "Umbral de % negativo que dispara la alerta"
  validation {
    condition     = var.negative_threshold_pct > 0 && var.negative_threshold_pct < 100
    error_message = "Entre 0 y 100."
  }
}

variable "team" {
  type        = string
  default     = "viega-cuneo"
  description = "Etiqueta team"
  validation {
    condition     = can(regex("^[a-z0-9_-]{1,63}$", var.team))
    error_message = "Etiqueta: minúsculas, números, guiones o guiones bajos."
  }
}

variable "owner" {
  type        = string
  default     = "avril-viega"
  description = "Etiqueta owner"
  validation {
    condition     = can(regex("^[a-z0-9_-]{1,63}$", var.owner))
    error_message = "Etiqueta: minúsculas, números, guiones o guiones bajos."
  }
}
