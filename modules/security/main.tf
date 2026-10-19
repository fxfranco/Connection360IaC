# ==================================================================================================
# Grupos de seguridad por capa (minimo privilegio). Flujo permitido:
#
#   Internet -> ALB (80/443) -> gateway (8080) -> api (8080) / notification (8080)
#   api / notification / etl -> datos (Postgres 5432, MongoDB 27017, Kafka 29092, "migraciones listas" 5499)
#   SSH (22): tu IP -> gateway; gateway -> el resto (el gateway hace de salto/bastion)
# ==================================================================================================

resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-sg-alb"
  description = "ALB publico"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP desde internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = var.enable_https ? [1] : []
    content {
      description = "HTTPS desde internet"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-sg-alb" }
}

resource "aws_security_group" "gateway" {
  name        = "${var.name_prefix}-sg-gateway"
  description = "Connection360.ApiGateway"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Gateway HTTP solo desde el ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "SSH desde tu IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-sg-gateway" }
}

resource "aws_security_group" "api" {
  name        = "${var.name_prefix}-sg-api"
  description = "Connection360.Api"
  vpc_id      = var.vpc_id

  ingress {
    description     = "API HTTP solo desde el gateway"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.gateway.id]
  }

  ingress {
    description     = "SSH desde el gateway (salto)"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.gateway.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-sg-api" }
}

resource "aws_security_group" "notification" {
  name        = "${var.name_prefix}-sg-notification"
  description = "Connection360Notification.Api"
  vpc_id      = var.vpc_id

  ingress {
    description     = "API HTTP/SignalR solo desde el gateway"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.gateway.id]
  }

  ingress {
    description     = "SSH desde el gateway (salto)"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.gateway.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-sg-notification" }
}

resource "aws_security_group" "etl" {
  name        = "${var.name_prefix}-sg-etl"
  description = "Connection360.Etl.Orchestrator / Etl.App"
  vpc_id      = var.vpc_id

  ingress {
    description     = "SSH desde el gateway (salto)"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.gateway.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-sg-etl" }
}

resource "aws_security_group" "data" {
  name        = "${var.name_prefix}-sg-data"
  description = "PostgreSQL, MongoDB y Kafka (contenedores)"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.api.id, aws_security_group.notification.id, aws_security_group.etl.id]
  }

  ingress {
    description     = "MongoDB"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.api.id, aws_security_group.notification.id, aws_security_group.etl.id]
  }

  ingress {
    description     = "Kafka (listener interno)"
    from_port       = 29092
    to_port         = 29092
    protocol        = "tcp"
    security_groups = [aws_security_group.api.id, aws_security_group.notification.id]
  }

  ingress {
    description     = "Senal migraciones Alembic terminadas"
    from_port       = 5499
    to_port         = 5499
    protocol        = "tcp"
    security_groups = [aws_security_group.api.id, aws_security_group.notification.id, aws_security_group.etl.id]
  }

  ingress {
    description     = "SSH desde el gateway (salto)"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.gateway.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-sg-data" }
}
