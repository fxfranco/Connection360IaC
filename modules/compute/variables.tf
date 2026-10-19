variable "name_prefix" {
  description = "Prefijo de nombres (proyecto-workspace)"
  type        = string
}

variable "key_name" {
  description = "Key pair EC2 existente (SSH)"
  type        = string
}

variable "instance_profile_name" {
  description = "Perfil de instancia existente (AWS Academy: LabInstanceProfile). Vacio = ninguno"
  type        = string
  default     = ""
}

variable "app_instances" {
  description = <<-EOT
    Instancias SIN estado (gateway, api, notification, etl). Se reemplazan si cambia su user_data
    (asi un cambio de version de imagen = despliegue nuevo). Clave del mapa = nombre corto.
  EOT
  type = map(object({
    ami_id             = string
    instance_type      = string
    subnet_id          = string
    private_ip         = string
    security_group_ids = list(string)
    public_ip          = bool
    root_volume_size   = number
  }))
}

variable "app_user_data" {
  description = "user_data (script de arranque) por clave de app_instances. Sensible: contiene secretos."
  type        = map(string)
  sensitive   = true
}

variable "data_instance" {
  description = <<-EOT
    Instancia CON estado (Postgres, MongoDB, Kafka, Zookeeper). NUNCA se reemplaza por cambios de
    user_data o de AMI: los datos viven en un volumen EBS aparte, pero reiniciar el stack sin necesidad es evitable.
  EOT
  type = object({
    ami_id             = string
    instance_type      = string
    subnet_id          = string
    private_ip         = string
    security_group_ids = list(string)
    root_volume_size   = number
  })
}

variable "data_user_data" {
  description = "user_data (script de arranque) de la instancia de datos. Sensible: contiene secretos."
  type        = string
  sensitive   = true
}
