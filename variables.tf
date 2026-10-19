# ==================================================================================================
# Variables de Connection360 en AWS (AWS Academy).
#   - Valores NO secretos:  environments/dev.tfvars        (terraform apply -var-file=environments/dev.tfvars)
#   - Valores secretos:     secrets.auto.tfvars            (se carga solo; NO se versiona; plantilla: secrets.auto.tfvars.example)
# ==================================================================================================

# ---------- General ----------
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  type    = string
  default = "seminario2"
}

variable "project_name" {
  description = "Prefijo para nombrar los recursos"
  type        = string
  default     = "connection360"
}

# ---------- Red ----------
variable "my_ip" {
  description = "IP publica permitida para SSH al gateway (CIDR /32)"
  type        = string
}

variable "vpc_cidr" {
  description = "Rango CIDR para la VPC"
  type        = string
}

variable "pub_subnets" {
  description = "CIDRs de las 2 subredes publicas (ALB + gateway)"
  type        = list(string)
}

variable "priv_subnets" {
  description = "CIDRs de las 2 subredes privadas (api, notification, etl, datos)"
  type        = list(string)
}

variable "availability_zone_a" {
  type = string
}

variable "availability_zone_b" {
  type = string
}

# ---------- Instancias ----------
variable "key_name" {
  description = "Key pair EC2 existente (SSH)"
  type        = string
}

variable "ami_id" {
  description = "AMI a usar. Vacio = ultima Amazon Linux 2023 x86_64"
  type        = string
  default     = ""
}

variable "instance_profile_name" {
  description = "Perfil de instancia existente (en AWS Academy: LabInstanceProfile). Vacio = sin perfil. No es necesario para el despliegue; solo habilita Session Manager (SSM)"
  type        = string
  default     = ""
}

variable "gateway_instance_type" {
  type    = string
  default = "t3.small"
}

variable "api_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "notification_instance_type" {
  type    = string
  default = "t3.small"
}

variable "etl_instance_type" {
  type    = string
  default = "t3.small"
}

variable "data_instance_type" {
  description = "Postgres + MongoDB + Kafka + Zookeeper en una sola instancia (recomendado >= 8 GB de RAM)"
  type        = string
  default     = "t3.large"
}

variable "data_volume_size" {
  description = "Tamano (GiB) del volumen EBS persistente de la instancia de datos"
  type        = number
  default     = 50
}

# ---------- Docker ----------
variable "registry" {
  description = "Usuario/organizacion de Docker Hub donde estan las imagenes"
  type        = string
  default     = "fxfranco13"
}

variable "dockerhub_username" {
  description = "Solo si los repositorios son privados"
  type        = string
  default     = ""
}

variable "dockerhub_token" {
  description = "Access token de Docker Hub (solo si los repositorios son privados)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "docker_compose_version" {
  type    = string
  default = "v2.29.7"
}

variable "apigateway_version" {
  type    = string
  default = "latest"
}

variable "api_version" {
  type    = string
  default = "latest"
}

variable "notification_api_version" {
  type    = string
  default = "latest"
}

variable "etl_orchestrator_version" {
  type    = string
  default = "latest"
}

variable "etl_app_version" {
  type    = string
  default = "latest"
}

variable "migrations_image" {
  description = "Imagen de migraciones Alembic (Connection360DataBase/postgres_db)"
  type        = string
  default     = "fxfranco13/connection360.migrations"
}

variable "migrations_version" {
  type    = string
  default = "latest"
}

variable "postgres_image_tag" {
  description = "Debe ser PostgreSQL 17 o superior (las migraciones usan GRANT MAINTAIN)"
  type        = string
  default     = "18-alpine"
}

variable "mongo_image_tag" {
  type    = string
  default = "8.0"
}

variable "kafka_image_tag" {
  type    = string
  default = "7.5.0"
}

# ---------- Bases de datos y Kafka ----------
variable "postgres_db_name" {
  type    = string
  default = "connection360_db"
}

variable "postgres_admin_user" {
  description = "Superusuario de Postgres (lo usa Alembic)"
  type        = string
  default     = "postgres"
}

variable "postgres_admin_password" {
  description = "Solo letras, numeros y . _ ~ - (minimo 12)"
  type        = string
  sensitive   = true
  validation {
    condition     = can(regex("^[A-Za-z0-9._~-]{12,}$", var.postgres_admin_password))
    error_message = "postgres_admin_password: minimo 12 caracteres, solo A-Z a-z 0-9 . _ ~ - (se usa dentro de URLs/cadenas de conexion)."
  }
}

variable "apicore_user_password" {
  description = "Password de apicore_user (usuario de la aplicacion .NET). Solo letras, numeros y . _ ~ -"
  type        = string
  sensitive   = true
  validation {
    condition     = can(regex("^[A-Za-z0-9._~-]{12,}$", var.apicore_user_password))
    error_message = "apicore_user_password: minimo 12 caracteres, solo A-Z a-z 0-9 . _ ~ - (se usa dentro de cadenas de conexion)."
  }
}

variable "mongo_root_user" {
  type    = string
  default = "root"
}

variable "mongo_root_password" {
  description = "Solo letras, numeros y . _ ~ - (minimo 12)"
  type        = string
  sensitive   = true
  validation {
    condition     = can(regex("^[A-Za-z0-9._~-]{12,}$", var.mongo_root_password))
    error_message = "mongo_root_password: minimo 12 caracteres, solo A-Z a-z 0-9 . _ ~ - (se usa dentro de la URI de MongoDB)."
  }
}

variable "mongo_database" {
  type    = string
  default = "connection360noti_db"
}

variable "mongo_notification_collection" {
  type    = string
  default = "notificationMessage"
}

variable "kafka_topic" {
  type    = string
  default = "notification-events"
}

variable "kafka_group_id" {
  type    = string
  default = "notification-consumer-group"
}

# ---------- Aplicacion: JWT, CORS, Auth0 ----------
variable "jwt_issuer" {
  type = string
}

variable "jwt_audience" {
  type = string
}

variable "jwt_roles" {
  type = string
}

variable "jwt_secret" {
  type      = string
  sensitive = true
  validation {
    condition     = length(var.jwt_secret) >= 32 && !can(regex("['\\n]", var.jwt_secret))
    error_message = "jwt_secret: minimo 32 caracteres, sin comillas simples ni saltos de linea."
  }
}

variable "cors_origins" {
  description = "Origenes del front permitidos por CORS (1 a 4)"
  type        = list(string)
  validation {
    condition     = length(var.cors_origins) >= 1 && length(var.cors_origins) <= 4
    error_message = "cors_origins: entre 1 y 4 origenes."
  }
}

variable "auth0_domain" {
  type = string
}

variable "auth0_client_id" {
  type = string
}

variable "auth0_client_secret" {
  type      = string
  sensitive = true
}

# ---------- Correo (Notification API) ----------
variable "smtp_server" {
  type    = string
  default = "smtp.gmail.com"
}

variable "smtp_port" {
  type    = number
  default = 465
}

variable "smtp_sender_name" {
  type    = string
  default = "Conexion360App"
}

variable "smtp_sender_email" {
  type = string
}

variable "smtp_password" {
  description = "Contrasena de APLICACION de Gmail"
  type        = string
  sensitive   = true
}

variable "smtp_recipient_email" {
  type = string
}

variable "smtp_check_cert_revocation" {
  type    = bool
  default = true
}

# ---------- ETL ----------
variable "etl_enabled" {
  type    = bool
  default = true
}

variable "etl_cron" {
  type    = string
  default = "*/5 * * * *"
}

variable "etl_timezone" {
  type    = string
  default = "America/Bogota"
}

variable "etl_timeout_minutes" {
  type    = number
  default = 15
}

variable "external_api_allow_invalid_cert" {
  description = "SOLO DESARROLLO: el ETL no valida el certificado TLS de las APIs externas"
  type        = bool
  default     = false
}

variable "external_apis" {
  description = "APIs externas que consume el ETL. Deben ser alcanzables DESDE AWS (IP publica/VPN), no una IP LAN privada."
  type = map(object({
    base_url = string
    api_key  = optional(string, "")
  }))
  sensitive = true
  validation {
    condition     = alltrue([for k in ["BPMS", "DATALOGS", "SIM", "OPENCOMEX", "ASISCOMEX", "SYSTEMCARRIER"] : contains(keys(var.external_apis), k)])
    error_message = "external_apis debe incluir las 6 claves: BPMS, DATALOGS, SIM, OPENCOMEX, ASISCOMEX y SYSTEMCARRIER."
  }
}

# ---------- Varios ----------
variable "log_level" {
  type    = string
  default = "Information"
}

variable "wait_for_data_seconds" {
  description = "Tiempo maximo que cada instancia espera a Postgres/Mongo/Kafka/migraciones al arrancar"
  type        = number
  default     = 900
}

variable "acm_certificate_arn" {
  description = "ARN de un certificado ACM. Si se define, el ALB agrega un listener HTTPS:443. Vacio = solo HTTP:80"
  type        = string
  default     = ""
}
