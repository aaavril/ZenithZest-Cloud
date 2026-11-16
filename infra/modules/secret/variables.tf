variable "project_id" {
  type        = string
  description = "ID del proyecto"
}

variable "secret_id" {
  type        = string
  description = "Nombre del secreto"
}

variable "labels" {
  type        = map(string)
  description = "Etiquetas obligatorias"
}

variable "accessors" {
  type        = list(string)
  default     = []
  description = "Miembros (serviceAccount:...) que pueden leer el valor"
}
