variable "project_id" {
  type        = string
  description = "ID del proyecto de Google Cloud"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "Región única del proyecto (la más barata con capa gratuita)"
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
}

variable "team" {
  type        = string
  default     = "viega-cuneo"
  description = "Etiqueta team"
}

variable "owner" {
  type        = string
  default     = "avril-viega"
  description = "Etiqueta owner (minúsculas, sin espacios)"
}
