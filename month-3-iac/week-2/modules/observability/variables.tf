variable "project_name" {
  description = "Used to name and tag all resources."
  type        = string
}

variable "aws_region" {
  description = "AWS region - used for the dashboard URL."
  type        = string
}

variable "instance_id" {
  description = "EC2 instance ID of the app server - passed in from the compute module."
  type        = string
}


variable "alert_email" {
  description = "Email address for CloudWatch alerts."
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs."
  type        = number
  default     = 30
}
