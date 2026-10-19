output "alb_dns" {
  description = "URL base para el front externo (HTTP). Ej.: curl http://<alb_dns>/health"
  value       = module.load_balancer.alb_dns
}

output "gateway_public_ip" {
  description = "IP publica del gateway (solo para SSH; cambia si la instancia se detiene y arranca)"
  value       = module.compute.app_public_ips["gateway"]
}

output "private_ips" {
  description = "IP privadas fijas de cada instancia"
  value = {
    gateway      = local.gateway_ip
    api          = local.api_ip
    notification = local.notification_ip
    etl          = local.etl_ip
    data         = local.data_ip
  }
}

output "data_volume_id" {
  description = "Volumen EBS con los datos de Postgres/Mongo/Kafka"
  value       = module.storage.data_volume_id
}

output "ssh_comandos" {
  description = "SSH al gateway y salto (-J) a las instancias privadas"
  value = {
    gateway      = "ssh -i <KP.pem> ec2-user@${module.compute.app_public_ips["gateway"]}"
    api          = "ssh -i <KP.pem> -J ec2-user@${module.compute.app_public_ips["gateway"]} ec2-user@${local.api_ip}"
    notification = "ssh -i <KP.pem> -J ec2-user@${module.compute.app_public_ips["gateway"]} ec2-user@${local.notification_ip}"
    etl          = "ssh -i <KP.pem> -J ec2-user@${module.compute.app_public_ips["gateway"]} ec2-user@${local.etl_ip}"
    data         = "ssh -i <KP.pem> -J ec2-user@${module.compute.app_public_ips["gateway"]} ec2-user@${local.data_ip}"
  }
}
