output "app_instance_ids" {
  value = { for k, v in aws_instance.app : k => v.id }
}

output "app_private_ips" {
  value = { for k, v in aws_instance.app : k => v.private_ip }
}

output "app_public_ips" {
  value = { for k, v in aws_instance.app : k => v.public_ip }
}

output "data_instance_id" {
  value = aws_instance.data.id
}

output "data_private_ip" {
  value = aws_instance.data.private_ip
}
