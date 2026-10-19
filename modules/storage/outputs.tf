output "data_volume_id" {
  description = "ID del volumen EBS (vol-xxxx); la instancia lo localiza por /dev/disk/by-id"
  value       = aws_ebs_volume.data.id
}
