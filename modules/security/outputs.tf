output "sg_alb_id" { value = aws_security_group.alb.id }
output "sg_gateway_id" { value = aws_security_group.gateway.id }
output "sg_api_id" { value = aws_security_group.api.id }
output "sg_notification_id" { value = aws_security_group.notification.id }
output "sg_etl_id" { value = aws_security_group.etl.id }
output "sg_data_id" { value = aws_security_group.data.id }
