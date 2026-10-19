locals {
  instance_profile = var.instance_profile_name == "" ? null : var.instance_profile_name
}

# --------------------------------------------------------------------------------------------------
# Instancias sin estado: gateway, api, notification, etl
# --------------------------------------------------------------------------------------------------
resource "aws_instance" "app" {
  for_each = var.app_instances

  ami                         = each.value.ami_id
  instance_type               = each.value.instance_type
  subnet_id                   = each.value.subnet_id
  private_ip                  = each.value.private_ip
  vpc_security_group_ids      = each.value.security_group_ids
  associate_public_ip_address = each.value.public_ip
  key_name                    = var.key_name
  iam_instance_profile        = local.instance_profile

  user_data_base64            = base64gzip(var.app_user_data[each.key])
  user_data_replace_on_change = true

  metadata_options {
    http_tokens   = "required" # IMDSv2
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_size           = each.value.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  tags = { Name = "${var.name_prefix}-${each.key}" }

  lifecycle {
    # Una AMI nueva de Amazon Linux no debe reemplazar instancias en marcha.
    ignore_changes = [ami]
  }
}

# --------------------------------------------------------------------------------------------------
# Instancia de datos
# --------------------------------------------------------------------------------------------------
resource "aws_instance" "data" {
  ami                         = var.data_instance.ami_id
  instance_type               = var.data_instance.instance_type
  subnet_id                   = var.data_instance.subnet_id
  private_ip                  = var.data_instance.private_ip
  vpc_security_group_ids      = var.data_instance.security_group_ids
  associate_public_ip_address = false
  key_name                    = var.key_name
  iam_instance_profile        = local.instance_profile

  user_data_base64            = base64gzip(var.data_user_data)
  user_data_replace_on_change = false

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_size           = var.data_instance.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  tags = { Name = "${var.name_prefix}-data" }

  lifecycle {
    ignore_changes = [ami, user_data_base64, user_data]
  }
}
