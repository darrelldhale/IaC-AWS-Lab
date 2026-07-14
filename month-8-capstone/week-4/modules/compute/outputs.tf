# === Output: ALB DNS NAME ===
# Used to access the app in a browser after apply.
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value = aws_lb.app_load_balancer.dns_name
}

# === Output: ECS Service Name ===
# Used to run CLI commands against the service - describe, update, exec.
output "ecs_service_name" {
  description = "Name of the ECS service"
  value = aws_ecs_service.ecs_service.name
}

# === Output: ECS Cluster Name ===
# Needed alongside service name for most ECS CLI commands.
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value = aws_ecs_cluster.ecs_cluster.name
}

# === Output: CodeDeploy Application Name ===
# Needed when triggering deployments via CLI.
output "codedeploy_app_name" {
  description = "Name of the CodeDeploy application"
  value       = aws_codedeploy_app.codedeploy_app.name
}

# === Output: CodeDeploy Deployment Group Name ===
# Needed alongside the app name to trigger a blue/green deployment.
output "codedeploy_deployment_group_name" {
  description = "Name of the CodeDeploy deployment group"
  value       = aws_codedeploy_deployment_group.codedeploy_deployment_group.deployment_group_name
}

# === Output: ECS Log Group Name ===
# Passed into the observability module so metric filters know which log group to watch
output "ecs_log_group_name" {
  description = "name of the ECS CloudWatch log group"
  value = aws_cloudwatch_log_group.ecs_log_group.name
}

# ARN suffix of the ALB, required for CloudWatch ALB metrics.
# CloudWatch dimensions use the suffix (app/name/id), not the full ARN.
output "alb_arn_suffix" {
  description = "ARN suffix of the application load balancer, for CloudWatch dimensions"
  value       = aws_lb.app_load_balancer.arn_suffix
}

# ARN suffix of the blue target group, required for HealthyHostCount.
output "blue_target_group_arn_suffix" {
  description = "ARN suffix of the blue target group, for CloudWatch dimensions"
  value       = aws_lb_target_group.blue_target_group.arn_suffix
}

