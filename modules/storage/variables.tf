variable "name_prefix" {
  description = "Prefijo de nombres (proyecto-workspace)"
  type        = string
}

variable "availability_zone" {
  description = "AZ del volumen: debe ser la misma de la instancia de datos"
  type        = string
}

variable "size_gib" {
  description = "Tamano del volumen de datos (GiB)"
  type        = number
}

variable "instance_id" {
  description = "Instancia de datos a la que se adjunta el volumen"
  type        = string
}

variable "device_name" {
  description = "Nombre de dispositivo para AWS (en instancias Nitro aparece como NVMe)"
  type        = string
  default     = "/dev/sdf"
}
