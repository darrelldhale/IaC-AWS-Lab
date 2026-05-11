variable "prefix" {
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
