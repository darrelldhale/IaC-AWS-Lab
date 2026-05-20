variable "project" {
  description = "Naming prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, prod)"
  type        = string
}

variable "log_group_name" {
  description = "Name of the CloudWatch log group to attach metric filters to"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "alert_email" {
  description = "Email address to receive CloudWatch alarm notifications"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster - used for CPU and memory alarm notifications"
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS service — used as a dimension for CPU and memory alarms"
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name used as the canary target URL"
  type        = string
}

variable "flow_log_group_name" {
  description = "Name of the CloudWatch Log Group receiving VPC flow logs — used for REJECT metric filter"
  type        = string
}
