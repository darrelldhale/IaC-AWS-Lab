variable "project_name" {
  description = "Used to name and tag resources."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC - passed in from the networking module."
  type        = string
}

variable "private_subnet_1_id" {
  description = "The ID of the first private subnet - where the EC2 instances will be deployed."
  type        = string
}

variable "ami_id" {
  description = "The ID of the AMI to use for the EC2 instances."
  type        = string
}

variable "instance_type" {
  description = "The type of EC2 instance to deploy."
  type        = string
  default     = "t2.micro"
}
