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
  description = "Región única del proyecto (la más barata con capa gratuita)"
  validation {
    condition     = can(regex("^[a-z]+-[a-z]+[0-9]$", var.region))
    error_message = "Región inválida (ej. us-central1)."
  }
}

variable "github_repo" {
  type        = string
  description = "Repositorio de GitHub en formato dueño/nombre, el único que puede usar la federación OIDC"
  validation {
    condition     = can(regex("^[^/]+/[^/]+$", var.github_repo))
    error_message = "Formato esperado: dueño/nombre."
  }
}

variable "billing_account" {
  type        = string
  default     = ""
  description = "ID de la cuenta de facturación (XXXXXX-XXXXXX-XXXXXX). Vacío = no crea el presupuesto"
  validation {
    condition     = var.billing_account == "" || can(regex("^[A-F0-9]{6}-[A-F0-9]{6}-[A-F0-9]{6}$", var.billing_account))
    error_message = "Formato XXXXXX-XXXXXX-XXXXXX (hexadecimal en mayúsculas) o vacío."
  }
}

variable "budget_usd" {
  type        = number
  default     = 10
  description = "Monto del presupuesto mensual en USD"
  validation {
    condition     = var.budget_usd > 0 && var.budget_usd <= 50
    error_message = "El presupuesto debe estar entre 1 y 50 USD."
  }
}

variable "team_emails" {
  type        = list(string)
  description = "Correos del equipo que reciben las alertas de presupuesto"
  validation {
    condition     = length(var.team_emails) > 0 && alltrue([for e in var.team_emails : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", e))])
    error_message = "Al menos un correo, todos con formato válido."
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
  description = "Etiqueta owner (minúsculas, sin espacios)"
  validation {
    condition     = can(regex("^[a-z0-9_-]{1,63}$", var.owner))
    error_message = "Etiqueta: minúsculas, números, guiones o guiones bajos."
  }
}
