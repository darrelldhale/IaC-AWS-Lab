variable "project" {
  description = "Project name used in resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, prod)"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID — used for S3 bucket naming and IAM policy ARNs"
  type        = string
}

variable "aws_region" {
  description = "AWS region — used in IAM policy ARNs for Config"
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
