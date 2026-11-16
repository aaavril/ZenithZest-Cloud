variable "project_id" {
  type        = string
  description = "ID del proyecto"
}

variable "region" {
  type        = string
  description = "Región de los buckets"
}

variable "name_prefix" {
  type        = string
  description = "Prefijo único global de los buckets (ej. <proyecto>-zz-dev)"
}

variable "labels" {
  type        = map(string)
  description = "Etiquetas obligatorias"
}

variable "input_files" {
  type        = map(string)
  default     = {}
  description = "Archivos a subir al bucket de entrada: nombre del objeto => ruta local"
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
