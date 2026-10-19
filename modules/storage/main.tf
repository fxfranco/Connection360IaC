# ==================================================================================================
# Almacenamiento persistente de la instancia de datos (PostgreSQL, MongoDB, Kafka, Zookeeper).
# Un volumen EBS SEPARADO de la instancia: si la instancia se reemplaza, los datos sobreviven.
# Dentro de la instancia se monta en /data y Docker guarda ahi sus volumenes (data-root=/data/docker).
#
# (Se retiro el EFS del lab k3s: una base de datos sobre NFS no es recomendable y aqui no se usa.)
# ==================================================================================================

resource "aws_ebs_volume" "data" {
  availability_zone = var.availability_zone
  size              = var.size_gib
  type              = "gp3"
  encrypted         = true

  tags = { Name = "${var.name_prefix}-data" }
}

resource "aws_volume_attachment" "data" {
  device_name = var.device_name
  volume_id   = aws_ebs_volume.data.id
  instance_id = var.instance_id

  # Evita bloqueos al destruir: Docker puede tener el disco abierto.
  stop_instance_before_detaching = true
}
