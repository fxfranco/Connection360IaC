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
  default = "patArquit"
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

variable "mongo_basic_user_collection" {
  description = "Coleccion de MongoDB donde Notification guarda los usuarios de Auth0 sincronizados (id, identificacion, correo, telefono)"
  type        = string
  default     = "basicUserData"
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
  description = "Correo de RESPALDO: se usa solo si el cliente no tiene un correo valido en basicUserData"
  type        = string
}

variable "smtp_conexion360_url" {
  description = "URL de Conexion360 que aparece como Consultar mi envio en el correo de cambio de estado (http/https). Vacia = sin enlace"
  type        = string
  default     = ""
}

variable "smtp_check_cert_revocation" {
  type    = bool
  default = true
}

# ---------- SMS (Brevo) - Connection360Notification.Api ----------
# URL base de la API de Brevo (debe terminar en "/"). Vacia = el servicio usa https://api.brevo.com/v3/.
variable "brevo_sms_base_url" {
  type    = string
  default = "https://api.brevo.com/v3/"
}

# API key de Brevo (transactionalSMS). Va en secrets.auto.tfvars, nunca en el repo.
variable "brevo_sms_api_key" {
  type      = string
  sensitive = true
  default   = ""
}

# Remitente del SMS: alfanumerico de hasta 11 caracteres (o numerico de hasta 15).
variable "brevo_sms_sender" {
  type    = string
  default = "Conexion360"
}

# URL de Conexion360 que se incluye en el texto del SMS (@URL conexion360@). Vacia = usa smtp_conexion360_url.
variable "brevo_sms_conexion360_url" {
  type    = string
  default = ""
}

# Indicativo de pais que se antepone a celulares sin indicativo (57 = Colombia).
variable "brevo_sms_default_country_code" {
  type    = string
  default = "57"
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

# ---------- Sincronizacion de usuarios Auth0 -> Notification (topico de Kafka -> coleccion basicUserData) ----------
variable "user_sync_enabled" {
  description = "Connection360.Api publica los usuarios de Auth0 al arrancar y de forma periodica"
  type        = bool
  default     = true
}

variable "user_sync_topic" {
  description = "Topico de Kafka de la sincronizacion (el mismo lo publica Api y lo consume Notification). El broker crea los topicos automaticamente"
  type        = string
  default     = "notification-users"
  validation {
    condition     = can(regex("^[A-Za-z0-9._-]{1,200}$", var.user_sync_topic))
    error_message = "user_sync_topic: solo letras, numeros, punto, guion y guion bajo (nombre valido de topico de Kafka)."
  }
}

variable "user_sync_interval_minutes" {
  description = "Cada cuantos minutos se repite la sincronizacion despues de la primera, que corre al arrancar"
  type        = number
  default     = 60
  validation {
    condition     = var.user_sync_interval_minutes >= 1
    error_message = "user_sync_interval_minutes debe ser como minimo 1."
  }
}

variable "user_sync_batch_size" {
  description = "Usuarios por mensaje de Kafka"
  type        = number
  default     = 200
  validation {
    condition     = var.user_sync_batch_size >= 1 && var.user_sync_batch_size <= 1000
    error_message = "user_sync_batch_size debe estar entre 1 y 1000."
  }
}

variable "user_sync_startup_retry_seconds" {
  description = "Espera entre los reintentos de la primera sincronizacion si Auth0 o Kafka aun no responden"
  type        = number
  default     = 30
  validation {
    condition     = var.user_sync_startup_retry_seconds >= 0
    error_message = "user_sync_startup_retry_seconds no puede ser negativo."
  }
}

variable "user_sync_group_id" {
  description = "Grupo de consumo del topico de usuarios en Notification. Vacio = <kafka_group_id>-users"
  type        = string
  default     = ""
}

variable "coordinates_cache_enabled" {
  description = "Cache en memoria de las coordenadas de OpenStreetMap en Connection360.Api (detalle de envios). false = siempre consulta a Nominatim"
  type        = bool
  default     = true
}

variable "coordinates_cache_max_size_mb" {
  description = "Tope de memoria de la cache de coordenadas, en MB (~1.600 lugares por MB). Al llenarse se descartan primero las entradas mas viejas"
  type        = number
  default     = 10
  validation {
    condition     = var.coordinates_cache_max_size_mb >= 1 && var.coordinates_cache_max_size_mb <= 256
    error_message = "coordinates_cache_max_size_mb debe estar entre 1 y 256 (la instancia comparte 4 GiB con el resto de contenedores)."
  }
}

variable "coordinates_cache_eviction_percentage" {
  description = "Fraccion de las entradas (0-1] que se libera de una vez al llegar al tope; se eliminan primero las menos usadas recientemente"
  type        = number
  default     = 0.2
  validation {
    condition     = var.coordinates_cache_eviction_percentage > 0 && var.coordinates_cache_eviction_percentage <= 1
    error_message = "coordinates_cache_eviction_percentage debe estar en el rango (0, 1]."
  }
}

variable "coordinates_cache_absolute_expiration_days" {
  description = "Dias maximos que una coordenada vive en la cache desde que se guardo"
  type        = number
  default     = 30
  validation {
    condition     = var.coordinates_cache_absolute_expiration_days >= 1 && floor(var.coordinates_cache_absolute_expiration_days) == var.coordinates_cache_absolute_expiration_days
    error_message = "coordinates_cache_absolute_expiration_days debe ser un entero mayor o igual a 1."
  }
}

variable "coordinates_cache_sliding_expiration_days" {
  description = "Dias sin consultarse tras los cuales una coordenada caduca"
  type        = number
  default     = 7
  validation {
    condition     = var.coordinates_cache_sliding_expiration_days >= 1 && floor(var.coordinates_cache_sliding_expiration_days) == var.coordinates_cache_sliding_expiration_days
    error_message = "coordinates_cache_sliding_expiration_days debe ser un entero mayor o igual a 1."
  }
}

variable "coordinates_cache_max_key_length" {
  description = "Longitud maxima del nombre del lugar que se cachea; los mas largos se consultan siempre a Nominatim"
  type        = number
  default     = 200
  validation {
    condition     = var.coordinates_cache_max_key_length >= 1 && floor(var.coordinates_cache_max_key_length) == var.coordinates_cache_max_key_length
    error_message = "coordinates_cache_max_key_length debe ser un entero mayor o igual a 1."
  }
}

variable "external_api_allow_invalid_cert" {
  description = "SOLO DESARROLLO: el ETL tolera certificados TLS autofirmados o de otro host en las APIs externas (rechaza los vencidos o revocados)"
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
