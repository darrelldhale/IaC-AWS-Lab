output "instance_id" {
  description = "The ID of the app server instance. Used for SSM Session Manager access."
  value       = aws_instance.app_server.id
}

output "private_ip" {
  description = "The private IP address of the app server instance."
  value       = aws_instance.app_server.private_ip
}

output "security_group_id" {
  description = "The ID of the security group attached to the app server instance."
  value       = aws_security_group.app_server_sg.id
}
