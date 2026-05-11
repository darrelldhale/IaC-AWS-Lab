terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # S3 Bucket To Hold State Files
  backend "s3" {
    bucket         = "sre-lab-tfstate-425924867120"
    key            = "month-5/week-1/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "sre-lab-tfstate-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

# Tags
locals {
  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "darrell"
    CostCenter  = "sre-lab"
  }
}

# Modules
module "networking" {
  source = "./modules/networking"

  project     = var.project
  environment = var.environment
  tags        = local.tags
}

module "compute" {
  source = "./modules/compute"

  project     = var.project
  environment = var.environment
  tags        = local.tags

  vpc_id = module.networking.vpc_id

  public_subnet_ids = [
    module.networking.public_subnet_1_id,
    module.networking.public_subnet_2_id
  ]

  private_subnet_ids = [
    module.networking.private_subnet_1_id,
    module.networking.private_subnet_2_id
  ]

  container_image = var.container_image
}

module "observability" {
  source = "./modules/observability"

  prefix      = var.project
  environment = var.environment
  tags        = local.tags

  # Log group created by the compute module - observability watches it for metric filters
  log_group_name = module.compute.ecs_log_group_name
}
