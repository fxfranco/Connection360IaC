# ==================================================================================================
# Connection360 en AWS Academy
#
#   Internet -> ALB (public) -> gateway (public subnet, Connection360.ApiGateway)
#                                   |-> api            (private subnet A, Connection360.Api)
#                                   |-> notification   (private subnet B, Connection360Notification.Api)
#   etl (private subnet A): Etl.Orchestrator + Etl.App
#   data (private subnet A): PostgreSQL + MongoDB + Zookeeper + Kafka + migraciones Alembic (disco EBS persistente)
#
# Todo corre en contenedores Docker (imagenes de Docker Hub). Ver README.md.
# ==================================================================================================

module "network" {
  source              = "./modules/network"
  vpc_cidr            = var.vpc_cidr
  pub_subnets         = var.pub_subnets
  priv_subnets        = var.priv_subnets
  availability_zone_a = var.availability_zone_a
  availability_zone_b = var.availability_zone_b
}

module "security" {
  source       = "./modules/security"
  vpc_id       = module.network.vpc_id
  my_ip        = var.my_ip
  name_prefix  = local.name_prefix
  enable_https = var.acm_certificate_arn != ""
}

# Falla ANTES de crear nada si algun valor trae comillas simples o saltos de linea (romperian el .env).
resource "terraform_data" "env_sanity" {
  lifecycle {
    precondition {
      condition     = !anytrue([for v in local.env_values_flat : can(regex("['\\n\\r]", v))])
      error_message = "Alguna variable (secretos, URLs, claves) contiene una comilla simple o un salto de linea; no se admiten porque se escriben entre comillas simples en el .env de cada instancia."
    }
  }
}

module "storage" {
  source            = "./modules/storage"
  name_prefix       = local.name_prefix
  availability_zone = var.availability_zone_a
  size_gib          = var.data_volume_size
  instance_id       = module.compute.data_instance_id
}

module "compute" {
  source                = "./modules/compute"
  name_prefix           = local.name_prefix
  key_name              = var.key_name
  instance_profile_name = var.instance_profile_name

  app_instances = {
    gateway = {
      ami_id             = local.ami_id
      instance_type      = var.gateway_instance_type
      subnet_id          = module.network.public_subnets[0]
      private_ip         = local.gateway_ip
      security_group_ids = [module.security.sg_gateway_id]
      public_ip          = true
      root_volume_size   = 30
    }
    api = {
      ami_id             = local.ami_id
      instance_type      = var.api_instance_type
      subnet_id          = module.network.private_subnets[0]
      private_ip         = local.api_ip
      security_group_ids = [module.security.sg_api_id]
      public_ip          = false
      root_volume_size   = 30
    }
    notification = {
      ami_id             = local.ami_id
      instance_type      = var.notification_instance_type
      subnet_id          = module.network.private_subnets[1]
      private_ip         = local.notification_ip
      security_group_ids = [module.security.sg_notification_id]
      public_ip          = false
      root_volume_size   = 30
    }
    etl = {
      ami_id             = local.ami_id
      instance_type      = var.etl_instance_type
      subnet_id          = module.network.private_subnets[0]
      private_ip         = local.etl_ip
      security_group_ids = [module.security.sg_etl_id]
      public_ip          = false
      root_volume_size   = 30
    }
  }

  data_instance = {
    ami_id             = local.ami_id
    instance_type      = var.data_instance_type
    subnet_id          = module.network.private_subnets[0]
    private_ip         = local.data_ip
    security_group_ids = [module.security.sg_data_id]
    root_volume_size   = 30
  }

  app_user_data  = local.user_data
  data_user_data = local.user_data_data

  # Las subredes privadas necesitan su ruta por la NAT antes de que arranquen las instancias
  # (descargan Docker, Compose e imagenes al iniciar).
  depends_on = [module.network, terraform_data.env_sanity]
}

module "load_balancer" {
  source              = "./modules/load_balancer"
  name_prefix         = local.name_prefix
  vpc_id              = module.network.vpc_id
  public_subnets      = module.network.public_subnets
  alb_sg_id           = module.security.sg_alb_id
  gateway_instance_id = module.compute.app_instance_ids["gateway"]
  acm_certificate_arn = var.acm_certificate_arn
}
