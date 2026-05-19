# === Output: ALB DNS NAME ===
# Used to access the app in a browser after apply.
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.compute.alb_dns_name
}

# === Output: ECS Service Name ===
# Used to run CLI commands against the service - describe, update, exec.
output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.compute.ecs_service_name
}

# === Output: ECS Cluster Name ===
# Needed alongside service name for most ECS CLI commands.
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.compute.ecs_cluster_name
}

# === Output: CodeDeploy Application Name ===
# Needed when triggering deployments via CLI.
output "codedeploy_app_name" {
  description = "Name of the CodeDeploy application"
  value       = module.compute.codedeploy_app_name
}

# === Output: CodeDeploy Deployment Group Name ===
# Needed alongside the CodeDeploy application name to trigger a blue/green deployment.
output "codedeploy_deployment_group_name" {
  description = "Name of the CodeDeploy deployment group"
  value       = module.compute.codedeploy_deployment_group_name
}

# === Output: 5xx Alarm Name ===
# Used to check alarm state via CLI or trigger test scenarios.
output "http_5xx_alarm_name" {
  description = "Name of the HTTP 5xx CloudWatch alarm"
  value       = module.observability.http_5xx_alarm_name
}

# === Output: ECS Log Group Name ===
# Used to run CloudWatch Logs Insights queries against container logs.
output "ecs_log_group_name" {
  description = "Name of the ECS CloudWatch log group"
  value       = module.compute.ecs_log_group_name
}

# === Output: ECS CPU Alarm Name ===
output "ecs_cpu_alarm_name" {
  description = "Name of the ECS CPU CloudWatch alarm"
  value       = module.observability.ecs_cpu_alarm_name
}

# === Output: ECS Memory Alarm Name ===
output "ecs_memory_alarm_name" {
  description = "Name of the ECS memory CloudWatch alarm"
  value       = module.observability.ecs_memory_alarm_name
}

# === Output: Guard Duty ID
output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector"
  value       = module.security.guardduty_detector_id
}

# === Output: Config S3 Bucket Name ===
output "config_s3_bucket_name" {
  description = "Name of the S3 bucket receiving Config history"
  value       = module.security.config_s3_bucket_name
}

# === Output: Security Hub Standards ARN ===
output "securityhub_standards_arn" {
  description = "ARN of the Security Hub standards subscription"
  value       = module.security.securityhub_standards_arn
}
