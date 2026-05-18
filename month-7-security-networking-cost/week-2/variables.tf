variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "project" {
  description = "Name of the project for tagging resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment for tagging and resource sizing (e.g., dev, staging, prod)"
  type        = string
}

variable "container_image" {
  description = "Container image to run in ECS Fargate tasks"
  type        = string
}

variable "alert_email" {
  description = "Email address to receive CloudWatch alarm notifications"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID — used for S3 bucket naming and IAM policy ARNs"
  type        = string
}
