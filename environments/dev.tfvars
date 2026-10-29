# ==================================================================================================
# Valores NO secretos del ambiente dev.   terraform apply -var-file=environments/dev.tfvars
# Los secretos van en secrets.auto.tfvars (se carga solo; NO se versiona).
# ==================================================================================================

# ---------- General ----------
aws_region   = "us-east-1"
aws_profile  = "seminario2"
project_name = "connection360"

# ---------- Red ----------
my_ip        = "200.122.208.2/32"
vpc_cidr     = "172.20.0.0/23"
pub_subnets  = ["172.20.0.0/26", "172.20.0.64/26"]
priv_subnets = ["172.20.0.128/26", "172.20.0.192/26"]

availability_zone_a = "us-east-1a"
availability_zone_b = "us-east-1b"

# ---------- Instancias (AWS Academy: familias t3 hasta large) ----------
key_name                   = "KP-Sem2"
instance_profile_name      = "" # opcional: "LabInstanceProfile" habilita Session Manager (SSM); el despliegue no lo necesita
gateway_instance_type      = "t3.small"
api_instance_type          = "t3.medium"
notification_instance_type = "t3.small"
etl_instance_type          = "t3.small"
data_instance_type         = "t3.large"
data_volume_size           = 50

# ---------- Imagenes Docker (Docker Hub) ----------
registry                 = "fxfranco13"
apigateway_version       = "1.0.0-alphabaseinit.1"
api_version              = "1.0.0-alphabaseinit.1"
notification_api_version = "1.0.0-alphabaseinit.1"
etl_orchestrator_version = "1.0.0-alphabaseinit.1"
etl_app_version          = "1.0.0-alphabaseinit.1"

# Imagen de migraciones Alembic (ver Connection360DataBase/postgres_db/deploy-migrations-image.md)
migrations_image   = "fxfranco13/connection360.migrations"
migrations_version = "latest"

# Si los repositorios de Docker Hub son privados, define dockerhub_username y dockerhub_token en secrets.auto.tfvars

# ---------- Bases de datos / Kafka ----------
postgres_image_tag            = "18-alpine" # PostgreSQL 17+ (las migraciones usan GRANT MAINTAIN)
mongo_image_tag               = "8.0"
kafka_image_tag               = "7.5.0"
postgres_db_name              = "connection360_db"
postgres_admin_user           = "postgres"
mongo_root_user               = "root"
mongo_database                = "connection360noti_db"
mongo_notification_collection = "notificationMessage"
mongo_basic_user_collection   = "basicUserData"
kafka_topic                   = "notification-events"
kafka_group_id                = "notification-consumer-group"

# ---------- Aplicacion ----------
jwt_issuer   = "https://login.conexion360.space/"
jwt_audience = "https://api.conexion360.com"
jwt_roles    = "https://conexion360.space/roles"

# Origenes del front permitidos por CORS (1 a 4). Pon aqui la URL real de tu front.
cors_origins = ["https://conexion360.space","http://localhost:4200"]

smtp_server                = "smtp.gmail.com"
smtp_port                  = 465
smtp_sender_name           = "Conexión360App"
smtp_check_cert_revocation = false
# URL de Conexion360 para el enlace "Consultar mi envio" del correo de cambio de estado.
smtp_conexion360_url       = "https://conexion360.space"

# ---------- SMS (Brevo) ----------
# URL base de la API de Brevo (con "/" final). Vacia = usa https://api.brevo.com/v3/
brevo_sms_base_url             = "https://api.brevo.com/v3/"
# Remitente alfanumerico de hasta 11 caracteres. La API key va en secrets.auto.tfvars (brevo_sms_api_key).
brevo_sms_sender               = "Conexion360"
# Vacio = usa smtp_conexion360_url en el texto del SMS.
brevo_sms_conexion360_url      = "https://conexion360.space"
# Indicativo que se antepone a celulares sin indicativo (57 = Colombia).
brevo_sms_default_country_code = "57"

# ---------- Sincronizacion de usuarios Auth0 -> Notification ----------
# El Api publica los usuarios de Auth0 al arrancar y luego cada user_sync_interval_minutes en el topico user_sync_topic;
# Notification los guarda sin duplicados en la coleccion mongo_basic_user_collection. Kafka crea el topico automaticamente.
# De cada usuario se envian el id de Auth0, su correo y, de su user_metadata, document, fullName y phone.number.
user_sync_enabled               = true
user_sync_topic                 = "notification-users"
user_sync_interval_minutes      = 10
user_sync_batch_size            = 200
user_sync_startup_retry_seconds = 30
# Vacio = "<kafka_group_id>-users"
user_sync_group_id = ""

# ---------- ETL ----------
etl_enabled         = true
etl_cron            = "*/5 * * * *"
etl_timezone        = "America/Bogota"
etl_timeout_minutes = 15

# SOLO DESARROLLO: true = el ETL acepta cualquier certificado TLS de las APIs externas (requiere imagen del ETL reconstruida).
external_api_allow_invalid_cert = false

# ---------- Varios ----------
log_level             = "Information"
wait_for_data_seconds = 900
acm_certificate_arn   = "" # ARN de un certificado ACM para activar HTTPS:443 en el ALB
