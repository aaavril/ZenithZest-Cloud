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
  description = "Región del job"
  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]$", var.region))
    error_message = "Región inválida (ej. us-central1)."
  }
}

variable "name" {
  type        = string
  description = "Nombre del job (también da nombre a su cuenta de servicio)"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{3,24}$", var.name))
    error_message = "Minúsculas, números y guiones; entre 4 y 25 caracteres."
  }
}

variable "image" {
  type        = string
  description = "Imagen del contenedor, por tag inmutable (SHA del commit) o digest"
  validation {
    condition     = !endswith(var.image, ":latest")
    error_message = "Nunca latest: usar el SHA del commit."
  }
}

variable "env" {
  type        = map(string)
  default     = {}
  description = "Variables de entorno NO sensibles del contenedor"
  validation {
    condition     = alltrue([for k in keys(var.env) : can(regex("^[A-Z][A-Z0-9_]*$", k))])
    error_message = "Nombres de variables de entorno en MAYÚSCULAS."
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

variable "max_retries" {
  type        = number
  default     = 1
  description = "Reintentos por tarea fallida"
  validation {
    condition     = var.max_retries >= 0 && var.max_retries <= 3
    error_message = "Entre 0 y 3."
  }
}

variable "timeout_seconds" {
  type        = number
  default     = 600
  description = "Tiempo máximo de una ejecución"
  validation {
    condition     = var.timeout_seconds >= 60 && var.timeout_seconds <= 3600
    error_message = "Entre 60 y 3600 segundos."
  }
}
