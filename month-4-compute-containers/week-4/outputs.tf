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

# === Output: ECR Repository URL ==
# Used to push custom Docker image to AWS after apply.
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.compute.ecr_repository_url
}

# === Output: CodeDeploy Application Name ===
# Needed when triggering deployments via CLI.
output "codedeploy_app_name" {
  description = "Name of the CodeDeploy application"
  value       = module.compute.codedeploy_app_name
}

# === Output: CodeDeploy Deployment Group Name ===
# Needed alongside the CodeDeploy app name to trigger a blue/green deployment.
output "codedeploy_deployment_group_name" {
  description = "Name of the CodeDeploy deployment group"
  value       = module.compute.codedeploy_deployment_group_name
}

