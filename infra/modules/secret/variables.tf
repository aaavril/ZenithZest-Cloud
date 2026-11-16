variable "project_id" {
  type        = string
  description = "ID del proyecto"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "ID de proyecto inválido."
  }
}

variable "secret_id" {
  type        = string
  description = "Nombre del secreto"
  validation {
    condition     = can(regex("^[A-Za-z0-9_-]{1,255}$", var.secret_id))
    error_message = "Solo letras, números, guiones y guiones bajos."
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

variable "accessors" {
  type        = list(string)
  default     = []
  description = "Miembros (serviceAccount:...) que pueden leer el valor"
  validation {
    condition     = alltrue([for m in var.accessors : startswith(m, "serviceAccount:")])
    error_message = "Solo cuentas de servicio (serviceAccount:...)."
  }
}
