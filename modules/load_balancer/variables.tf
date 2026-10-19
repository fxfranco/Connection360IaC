variable "name_prefix" {
  description = "Prefijo de nombres (proyecto-workspace). Maximo ~20 caracteres (limite de 32 del ALB/TG)"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "public_subnets" {
  description = "Subredes publicas del ALB (2 AZ)"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "Security group del ALB"
  type        = string
}

variable "gateway_instance_id" {
  description = "Instancia donde corre Connection360.ApiGateway"
  type        = string
}

variable "target_port" {
  description = "Puerto HTTP del gateway en la instancia"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "Ruta de salud del gateway"
  type        = string
  default     = "/health"
}

variable "acm_certificate_arn" {
  description = "Si no esta vacio, se crea el listener HTTPS:443 con este certificado"
  type        = string
  default     = ""
}
