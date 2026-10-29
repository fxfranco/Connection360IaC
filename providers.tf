terraform {
  required_version = ">= 1.5.0"

  # Estado NUEVO para el despliegue de Connection360 (el lab k3s anterior usaba la key
  # "01-k3s-lab/terraform.tfstate" y NO se toca). Después de cambiar la key ejecuta:
  #   terraform init -reconfigure
  backend "s3" {
    bucket       = "chfranco.patarquitvscode2026-2"
    key          = "connection360/terraform.tfstate"
    use_lockfile = true
    region       = "us-east-1"
    encrypt      = true
    profile      = "patArquit"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = terraform.workspace
      ManagedBy   = "terraform"
    }
  }
}
