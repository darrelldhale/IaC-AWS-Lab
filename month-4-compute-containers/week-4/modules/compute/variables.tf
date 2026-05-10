variable "project" {
  description = "Project name for naming and tagging resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
}

variable "vpc_id" {
  description = "VPC ID from networking module"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the load balancer"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for Fargate tasks"
  type        = list(string)
}

variable "container_image" {
  description = "Container image to run in Fargate tasks"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 80
}

variable "task_cpu" {
  description = "CPU units for the Fargate task (256, 512, 1024)"
  type = number
  default = 256
}

variable "task_memory" {
  description = "Memory in MiB for the Fargate task (512, 1024, 2048)"
  type = number
  default = 512
}

variable "desired_count" {
  description = "Desired number of Fargate tasks"
  type = number
  default = 2
}

variable "deployment_wait_time" {
  description = "Minutes CodeDeploy waits before terminating old blue tasks after traffic shift"
  type = number
  default = 5
}
