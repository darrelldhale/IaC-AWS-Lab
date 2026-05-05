variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Used to tag and name all resources"
  type        = string
  default     = "sre-lab"
}

variable "ami_id" {
  description = "The ID of the AMI to use for EC2 instances"
  type        = string
  default     = "ami-0eb38b817b93460ac"
}

variable "instance_type" {
  description = "The type of EC2 instance to use"
  type        = string
  default     = "t2.micro"
}

variable "alert_email" {
  description = "Email address to receive alerts"
  type        = string
  default     = "myawstraining2026@gmail.com"
}
