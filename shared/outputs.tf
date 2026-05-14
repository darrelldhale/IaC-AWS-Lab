output "ecr_repository_url" {
  description = "ECR repository URL — use this in terraform.tfvars for container_image"
  value       = aws_ecr_repository.ecr_repo.repository_url
}
