# ==================================================================================================
# Valores derivados: IP privadas FIJAS, cadenas de conexion, archivos .env y user_data de cada instancia.
#
# Por que IP fijas: las instancias se conocen entre si (gateway -> apis, apis -> datos) sin DNS ni
# descubrimiento, y no cambian aunque AWS Academy detenga/arranque las instancias entre sesiones.
# ==================================================================================================

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  name_prefix = "${var.project_name}-${terraform.workspace}"
  ami_id      = var.ami_id != "" ? var.ami_id : data.aws_ami.al2023.id

  # ---------- IP privadas fijas (el host 10+ queda fuera del rango reservado por AWS) ----------
  gateway_ip      = cidrhost(var.pub_subnets[0], 10)
  api_ip          = cidrhost(var.priv_subnets[0], 10)
  data_ip         = cidrhost(var.priv_subnets[0], 11)
  etl_ip          = cidrhost(var.priv_subnets[0], 12)
  notification_ip = cidrhost(var.priv_subnets[1], 10)

  # ---------- Cadenas de conexion (mismos formatos que .env.example del repositorio) ----------
  postgres_connection = "Host=${local.data_ip};Port=5432;Database=${var.postgres_db_name};Username=apicore_user;Password=${var.apicore_user_password};Pooling=true;Minimum Pool Size=0;Maximum Pool Size=100;Connection Lifetime=300;"
  mongo_connection    = "mongodb://${var.mongo_root_user}:${var.mongo_root_password}@${local.data_ip}:27017/${var.mongo_database}?authSource=admin"
  kafka_bootstrap     = "${local.data_ip}:29092"

  cors = [for i in range(4) : try(var.cors_origins[i], "")]

  # ---------- Variables que comparten varias instancias ----------
  env_common = {
    REGISTRY          = var.registry
    LOG_LEVEL_DEFAULT = var.log_level
  }

  env_jwt = {
    JWT_ISSUER   = var.jwt_issuer
    JWT_AUDIENCE = var.jwt_audience
    JWT_ROLES    = var.jwt_roles
    JWT_SECRET   = var.jwt_secret
  }

  env_mongo_observability = {
    OBSERVABILITY_ENABLED = "true"
    MONGO_CONNECTION      = local.mongo_connection
    MONGO_DATABASE        = var.mongo_database
  }

  env_kafka = {
    KAFKA_BOOTSTRAP_SERVERS = local.kafka_bootstrap
    KAFKA_GROUP_ID          = var.kafka_group_id
    KAFKA_TOPIC             = var.kafka_topic
  }

  # ---------- .env de cada instancia (los lee docker compose; nombres = .env.example del repositorio) ----------
  env_maps = {
    gateway = merge(local.env_common, local.env_jwt, {
      APIGATEWAY_VERSION        = var.apigateway_version
      CORE_API_URL              = "http://${local.api_ip}:8080/"
      NOTIFICATION_API_URL      = "http://${local.notification_ip}:8080/"
      JWT_ACCESS_TOKEN_MINUTES  = "15"
      JWT_REFRESH_TOKEN_DAYS    = "7"
      RATE_LIMIT_PERMIT_LIMIT   = "100"
      RATE_LIMIT_WINDOW_SECONDS = "60"
      RATE_LIMIT_QUEUE_LIMIT    = "0"
      CORS_ORIGIN_0             = local.cors[0]
      CORS_ORIGIN_1             = local.cors[1]
      CORS_ORIGIN_2             = local.cors[2]
      CORS_ORIGIN_3             = local.cors[3]
    })

    api = merge(local.env_common, local.env_jwt, local.env_mongo_observability, local.env_kafka, {
      API_VERSION                     = var.api_version
      POSTGRES_CONNECTION             = local.postgres_connection
      AUTH0_DOMAIN                    = var.auth0_domain
      AUTH0_CLIENT_ID                 = var.auth0_client_id
      AUTH0_CLIENT_SECRET             = var.auth0_client_secret
      OUTBOX_POLLING_INTERVAL_SECONDS = "10"
      OPENSTREETMAP_BASE_URL          = "https://nominatim.openstreetmap.org"
      OPENSTREETMAP_API_KEY           = ""
      EXTERNAL_API_TIMEOUT_SECONDS    = "30"

      # Sincronizacion de usuarios de Auth0 hacia Notification (Auth0UserSync__* en el Api)
      USER_SYNC_ENABLED               = tostring(var.user_sync_enabled)
      USER_SYNC_TOPIC                 = var.user_sync_topic
      USER_SYNC_INTERVAL_MINUTES      = tostring(var.user_sync_interval_minutes)
      USER_SYNC_BATCH_SIZE            = tostring(var.user_sync_batch_size)
      USER_SYNC_STARTUP_RETRY_SECONDS = tostring(var.user_sync_startup_retry_seconds)
    })

    notification = merge(local.env_common, local.env_jwt, local.env_mongo_observability, local.env_kafka, {
      NOTIFICATION_API_VERSION      = var.notification_api_version
      POSTGRES_CONNECTION           = local.postgres_connection
      MONGO_NOTIFICATION_COLLECTION = var.mongo_notification_collection
      MONGO_BASIC_USER_COLLECTION   = var.mongo_basic_user_collection
      USER_SYNC_TOPIC               = var.user_sync_topic
      USER_SYNC_GROUP_ID            = var.user_sync_group_id
      SMTP_SERVER                   = var.smtp_server
      SMTP_PORT                     = tostring(var.smtp_port)
      SMTP_SENDER_NAME              = var.smtp_sender_name
      SMTP_SENDER_EMAIL             = var.smtp_sender_email
      SMTP_PASSWORD                 = var.smtp_password
      SMTP_RECIPIENT_EMAIL          = var.smtp_recipient_email
      SMTP_CONEXION360_URL          = var.smtp_conexion360_url
      SMTP_TIMEOUT_SECONDS          = "30"
      SMTP_CHECK_CERT_REVOCATION    = tostring(var.smtp_check_cert_revocation)
    })

    etl = merge(local.env_common, local.env_mongo_observability, {
      ETL_ORCHESTRATOR_VERSION          = var.etl_orchestrator_version
      ETL_APP_VERSION                   = var.etl_app_version
      POSTGRES_CONNECTION               = local.postgres_connection
      ETL_ENABLED                       = tostring(var.etl_enabled)
      ETL_CRON                          = var.etl_cron
      ETL_TIMEZONE                      = var.etl_timezone
      ETL_TIMEOUT_MINUTES               = tostring(var.etl_timeout_minutes)
      ETL_JOB_CONTROL_RETENTION_DAYS    = "2"
      ETL_VIEWS_REFRESH_ENABLED         = "true"
      ETL_VIEWS_COMMAND_TIMEOUT_SECONDS = "600"
      ETL_SYSTEM_USER                   = "ETL_CONNECTION360"
      EXTERNAL_API_TIMEOUT_SECONDS      = "30"
      EXTERNAL_API_PAGINATION_ENABLED   = "false"
      EXTERNAL_API_PAGE_SIZE            = "500"
      EXTERNAL_API_ALLOW_INVALID_CERT   = tostring(var.external_api_allow_invalid_cert)
      BPMS_BASE_URL                     = var.external_apis["BPMS"].base_url
      BPMS_API_KEY                      = var.external_apis["BPMS"].api_key
      DATALOGS_BASE_URL                 = var.external_apis["DATALOGS"].base_url
      DATALOGS_API_KEY                  = var.external_apis["DATALOGS"].api_key
      SIM_BASE_URL                      = var.external_apis["SIM"].base_url
      SIM_API_KEY                       = var.external_apis["SIM"].api_key
      OPENCOMEX_BASE_URL                = var.external_apis["OPENCOMEX"].base_url
      OPENCOMEX_API_KEY                 = var.external_apis["OPENCOMEX"].api_key
      ASISCOMEX_BASE_URL                = var.external_apis["ASISCOMEX"].base_url
      ASISCOMEX_API_KEY                 = var.external_apis["ASISCOMEX"].api_key
      SYSTEMCARRIER_BASE_URL            = var.external_apis["SYSTEMCARRIER"].base_url
      SYSTEMCARRIER_API_KEY             = var.external_apis["SYSTEMCARRIER"].api_key
    })

    data = {
      POSTGRES_IMAGE_TAG    = var.postgres_image_tag
      MONGO_IMAGE_TAG       = var.mongo_image_tag
      KAFKA_IMAGE_TAG       = var.kafka_image_tag
      POSTGRES_USER         = var.postgres_admin_user
      POSTGRES_PASSWORD     = var.postgres_admin_password
      POSTGRES_DB           = var.postgres_db_name
      APICORE_USER_PASSWORD = var.apicore_user_password
      MONGO_ROOT_USER       = var.mongo_root_user
      MONGO_ROOT_PASSWORD   = var.mongo_root_password
      DATA_PRIVATE_IP       = local.data_ip
      MIGRATIONS_IMAGE      = var.migrations_image
      MIGRATIONS_VERSION    = var.migrations_version
    }
  }

  # Valores entre comillas simples (docker compose no interpola $ ni interpreta caracteres especiales).
  env_text = {
    for role, m in local.env_maps :
    role => join("\n", [for k in sort(keys(m)) : "${k}='${m[k]}'"])
  }

  # Ninguna variable puede traer comillas simples ni saltos de linea (romperian el .env).
  env_values_flat = flatten([for m in values(local.env_maps) : values(m)])

  # ---------- Archivos que se escriben en cada instancia ----------
  app_dir = "/opt/connection360"

  files_by_role = {
    gateway = [
      { path = "${local.app_dir}/docker-compose.yml", mode = "0644", content = file("${path.root}/templates/compose/gateway.yml") },
      { path = "${local.app_dir}/.env", mode = "0600", content = local.env_text.gateway },
      { path = "${local.app_dir}/redeploy.sh", mode = "0755", content = file("${path.root}/templates/files/redeploy.sh") },
    ]
    api = [
      { path = "${local.app_dir}/docker-compose.yml", mode = "0644", content = file("${path.root}/templates/compose/api.yml") },
      { path = "${local.app_dir}/.env", mode = "0600", content = local.env_text.api },
      { path = "${local.app_dir}/redeploy.sh", mode = "0755", content = file("${path.root}/templates/files/redeploy.sh") },
    ]
    notification = [
      { path = "${local.app_dir}/docker-compose.yml", mode = "0644", content = file("${path.root}/templates/compose/notification.yml") },
      { path = "${local.app_dir}/.env", mode = "0600", content = local.env_text.notification },
      { path = "${local.app_dir}/redeploy.sh", mode = "0755", content = file("${path.root}/templates/files/redeploy.sh") },
    ]
    etl = [
      { path = "${local.app_dir}/docker-compose.yml", mode = "0644", content = file("${path.root}/templates/compose/etl.yml") },
      { path = "${local.app_dir}/.env", mode = "0600", content = local.env_text.etl },
      { path = "${local.app_dir}/redeploy.sh", mode = "0755", content = file("${path.root}/templates/files/redeploy.sh") },
    ]
    data = [
      { path = "${local.app_dir}/docker-compose.yml", mode = "0644", content = file("${path.root}/templates/compose/data.yml") },
      { path = "${local.app_dir}/.env", mode = "0600", content = local.env_text.data },
      { path = "${local.app_dir}/db-init/01-init.sh", mode = "0755", content = file("${path.root}/templates/files/db-init-01-init.sh") },
      { path = "${local.app_dir}/run-migrations.sh", mode = "0755", content = file("${path.root}/templates/files/run-migrations.sh") },
      { path = "${local.app_dir}/redeploy.sh", mode = "0755", content = file("${path.root}/templates/files/redeploy.sh") },
    ]
  }

  files_snippet = {
    for role, files in local.files_by_role :
    role => join("\n", concat(
      ["", "# ---- Archivos de configuracion de ${role} ----"],
      [for f in files : "mkdir -p \"$(dirname ${f.path})\"\ncat > ${f.path} <<'C360_FILE_EOF'\n${f.content}\nC360_FILE_EOF\nchmod ${f.mode} ${f.path}"]
    ))
  }

  # ---------- Esperas de dependencias al arrancar (las apps esperan a la instancia de datos) ----------
  wait_lines = {
    gateway = ""
    api = join("\n", [
      "wait_for ${local.data_ip} 5499 \"migraciones Alembic\"",
      "wait_for ${local.data_ip} 27017 MongoDB",
      "wait_for ${local.data_ip} 29092 Kafka",
    ])
    notification = join("\n", [
      "wait_for ${local.data_ip} 5499 \"migraciones Alembic\"",
      "wait_for ${local.data_ip} 27017 MongoDB",
      "wait_for ${local.data_ip} 29092 Kafka",
    ])
    etl = join("\n", [
      "wait_for ${local.data_ip} 5499 \"migraciones Alembic\"",
      "wait_for ${local.data_ip} 27017 MongoDB",
    ])
  }

  # ---------- Docker ----------
  docker_login_text = <<-EOT

    echo "[bootstrap] docker login (${var.dockerhub_username})"
    docker login -u '${var.dockerhub_username}' --password-stdin <<'C360_TOKEN_EOF'
    ${var.dockerhub_token}
    C360_TOKEN_EOF
  EOT

  docker_login_snippet = var.dockerhub_username != "" && var.dockerhub_token != "" ? local.docker_login_text : ""

  docker_systemd_data = <<-EOT
    mkdir -p /etc/systemd/system/docker.service.d
    cat > /etc/systemd/system/docker.service.d/10-wait-data-mount.conf <<'C360_SD_EOF'
    [Unit]
    RequiresMountsFor=/data
    C360_SD_EOF
  EOT

  daemon_json_app = jsonencode({
    "log-driver" = "json-file"
    "log-opts"   = { "max-size" = "20m", "max-file" = "5" }
  })

  daemon_json_data = jsonencode({
    "log-driver" = "json-file"
    "log-opts"   = { "max-size" = "20m", "max-file" = "5" }
    "data-root"  = "/data/docker"
  })

  tpl = "${path.root}/templates/bootstrap"

  # ---------- user_data por rol ----------
  user_data = {
    for role in ["gateway", "api", "notification", "etl"] :
    role => join("\n", [
      templatefile("${local.tpl}/00-header.sh.tftpl", { role = role, wait_seconds = var.wait_for_data_seconds }),
      templatefile("${local.tpl}/20-docker.sh.tftpl", {
        daemon_json            = local.daemon_json_app
        docker_systemd_snippet = ""
        compose_version        = var.docker_compose_version
        docker_login_snippet   = local.docker_login_snippet
      }),
      local.files_snippet[role],
      templatefile("${local.tpl}/90-start-app.sh.tftpl", { wait_lines = local.wait_lines[role] }),
    ])
  }

  # La instancia de datos monta el disco EBS persistente y guarda ahi los volumenes de Docker.
  user_data_data = join("\n", [
    templatefile("${local.tpl}/00-header.sh.tftpl", { role = "data", wait_seconds = var.wait_for_data_seconds }),
    templatefile("${local.tpl}/10-data-disk.sh.tftpl", { volume_id = module.storage.data_volume_id }),
    templatefile("${local.tpl}/20-docker.sh.tftpl", {
      daemon_json            = local.daemon_json_data
      docker_systemd_snippet = local.docker_systemd_data
      compose_version        = var.docker_compose_version
      docker_login_snippet   = local.docker_login_snippet
    }),
    local.files_snippet["data"],
    templatefile("${local.tpl}/90-start-data.sh.tftpl", {}),
  ])
}
