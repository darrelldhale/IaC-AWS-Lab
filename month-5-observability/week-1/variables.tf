variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Name of the project for tagging resources"
  type        = string
  default     = "sre-lab"
}

variable "environment" {
  description = "Deployment environment for tagging and resource sizing (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "container_image" {
  description = "Container image to run in ECS Fargate tasks"
  type        = string
  default     = "425924867120.dkr.ecr.us-east-1.amazonaws.com/sre-lab-dev-ecr-repo:v5"
}
