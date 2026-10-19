variable "vpc_id" {
  description = "ID de la VPC creada en el modulo network"
  type        = string
}

variable "my_ip" {
  description = "Tu IP publica con /32 para SSH al gateway"
  type        = string
}

variable "name_prefix" {
  description = "Prefijo de nombres (proyecto-workspace)"
  type        = string
}

variable "enable_https" {
  description = "Abre 443 en el ALB (solo si hay certificado)"
  type        = bool
  default     = false
}
