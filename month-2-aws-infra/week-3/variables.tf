variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Used to tag and name all resources"
  type        = string
  default     = "sre-lab"
}

variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
}
