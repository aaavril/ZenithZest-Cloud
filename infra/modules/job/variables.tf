variable "project_id" {
  type        = string
  description = "ID del proyecto"
}

variable "region" {
  type        = string
  description = "Región del job"
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
}

variable "labels" {
  type        = map(string)
  description = "Etiquetas obligatorias"
}

variable "max_retries" {
  type        = number
  default     = 1
  description = "Reintentos por tarea fallida"
}

variable "timeout_seconds" {
  type        = number
  default     = 600
  description = "Tiempo máximo de una ejecución"
}
