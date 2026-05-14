terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Shared infrastructure state — never destroyed between weeks
  backend "s3" {
    bucket         = "sre-lab-tfstate-425924867120"
    key            = "shared/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "sre-lab-tfstate-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

# ECR repository — lives here permanently, outside any week's state
# Images accumulate across all versions and are never wiped by a weekly destroy
resource "aws_ecr_repository" "ecr_repo" {
  name                 = "sre-lab-dev-ecr-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project     = "sre-lab"
    Environment = "dev"
    ManagedBy   = "terraform"
    Name        = "sre-lab-dev-ecr-repo"
    Owner       = "darrell"
    CostCenter  = "sre-lab"
  }
}
