output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "nat_gateway_ip" {
  description = "Public IP of the NAT Gateway"
  value       = module.networking.nat_gateway_ip
}

output "app_server_instance_id" {
  description = "Instance ID of the app server — use for SSM access"
  value       = module.compute.instance_id
}

output "app_server_private_ip" {
  description = "Private IP of the app server"
  value       = module.compute.private_ip
}

output "sns_topic_arn" {
  description = "ARN of the SNS alerts topic"
  value       = module.observability.sns_topic_arn
}

output "dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = module.observability.dashboard_url
}

output "log_group_name" {
  description = "CloudWatch log group for nginx logs"
  value       = module.observability.log_group_name
}
