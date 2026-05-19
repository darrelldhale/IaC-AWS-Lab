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

# Dedicated IAM user for the GitHub Actions pipeline
# Persists between lab sessions — never destroyed
resource "aws_iam_user" "pipeline_user" {
  name          = "github-actions-pipeline"
  force_destroy = true
  tags = {
    Project     = "sre-lab"
    Environment = "dev"
    ManagedBy   = "terraform"
    Owner       = "darrell"
    CostCenter  = "sre-lab"
  }
}

# Least-privilege policy scoped to exactly what the pipeline needs
resource "aws_iam_policy" "pipeline_policy" {
  name        = "sre-lab-github-actions-pipeline-policy"
  description = "Scoped permissions for the GitHub Actions CI/CD pipeline"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ECRAuth"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "ECRPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "arn:aws:ecr:us-east-1:425924867120:repository/sre-lab-dev-ecr-repo"
      },
      {
        Sid    = "ECSTaskDefinition"
        Effect = "Allow"
        Action = [
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition"
        ]
        Resource = "*"
      },
      {
        Sid      = "PassRole"
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = "arn:aws:iam::425924867120:role/sre-lab-dev-*"
      },
      {
        Sid    = "CodeDeploy"
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:GetApplicationRevision",
          "codedeploy:RegisterApplicationRevision"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the policy to the pipeline user
resource "aws_iam_user_policy_attachment" "pipeline" {
  user       = aws_iam_user.pipeline_user.name
  policy_arn = aws_iam_policy.pipeline_policy.arn
}
