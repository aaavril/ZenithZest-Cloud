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
  description = "Región de los buckets"
  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]$", var.region))
    error_message = "Región inválida (ej. us-central1)."
  }
}

variable "name_prefix" {
  type        = string
  description = "Prefijo único global de los buckets (ej. <proyecto>-zz-dev)"
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{2,50}$", var.name_prefix))
    error_message = "Prefijo: minúsculas, números y guiones; máximo 51 caracteres (el nombre del bucket tiene tope de 63)."
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

variable "input_files" {
  type        = map(string)
  default     = {}
  description = "Archivos a subir al bucket de entrada: nombre del objeto => ruta local"
  validation {
    condition     = alltrue([for k in keys(var.input_files) : endswith(k, ".csv")])
    error_message = "Solo archivos .csv."
  }
}

variable "input_ttl_days" {
  type        = number
  default     = 30
  description = "Días que viven los objetos de entrada"
  validation {
    condition     = var.input_ttl_days >= 1 && var.input_ttl_days <= 90
    error_message = "Entre 1 y 90 días."
  }
}

variable "reports_ttl_days" {
  type        = number
  default     = 14
  description = "Días que viven los reportes generados"
  validation {
    condition     = var.reports_ttl_days >= 1 && var.reports_ttl_days <= 90
    error_message = "Entre 1 y 90 días."
  }
}
