output "app_server_instance_id" {
  description = "Instance ID of the App Server — use this for SSM access"
  value       = aws_instance.app_server.id
}

output "app_server_private_ip" {
  description = "Private IP of the App Server"
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

output "sns_topic_arn" {
  description = "ARN of the SNS alerts topic"
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "log_group_name" {
  description = "CloudWatch log group for nginx logs"
  value       = aws_cloudwatch_log_group.nginx.name
}
