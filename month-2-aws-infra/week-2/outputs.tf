output "app_server_private_ip" {
  description = "Private IP of the Application Server"
  value       = aws_instance.app_server.private_ip
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "nat_gateway_ip" {
  description = "Public IP of the NAT Gateway"
  value       = aws_eip.nat.public_ip
}

output "app_server_instance_id" {
  description = "Instance ID of the Application Server for SSM access"
  value       = aws_instance.app_server.id
}
