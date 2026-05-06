terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"

  backend "s3" {
    bucket         = "sre-lab-tfstate-425924867120"
    key            = "month-3/week-2/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "sre-lab-tfstate-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

module "networking" {
  source         = "./modules/networking"
  project_name   = var.project_name
  aws_region     = var.aws_region
  vpc_cidr_block = "10.0.0.0/16"
}

module "compute" {
  source              = "./modules/compute"
  project_name        = var.project_name
  vpc_id              = module.networking.vpc_id
  private_subnet_1_id = module.networking.private_subnet_1_id
  ami_id              = var.ami_id
  instance_type       = terraform.workspace == "prod" ? "t3.small" : "t2.micro"
}

module "observability" {
  source             = "./modules/observability"
  project_name       = var.project_name
  aws_region         = var.aws_region
  instance_id        = module.compute.instance_id
  alert_email        = var.alert_email
  log_retention_days = terraform.workspace == "prod" ? 30 : 7
}
