terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    # Archive provider: zips the canary script so Terraform can hand it to Lambda
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

  # S3 Bucket To Hold State Files
  backend "s3" {
    bucket         = "sre-lab-tfstate-425924867120"
    key            = "month-6/week-2/terraform.tfstate"
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

  project     = var.project
  environment = var.environment
  tags        = local.tags

  # Log group created by the compute module - observability watches it for metric filters
  log_group_name = module.compute.ecs_log_group_name

  # Email address for alarm notifications via SNS
  alert_email = var.alert_email

  # ECS cluster name used as a dimension for CPU and memory alarms
  ecs_cluster_name = module.compute.ecs_cluster_name

  # ECS service name used as a dimension for CPU and memory alarms
  ecs_service_name = module.compute.ecs_service_name

  # ALB DNS name - passed to the canary as its target URL
  alb_dns_name = module.compute.alb_dns_name
}

# ====== FIS: Chaos Engineering =========================================

# The trust policy allows the FIS service itself to assume it
data "aws_iam_policy_document" "fis_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["fis.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# IAM Role: FIS runs experiments as this role
resource "aws_iam_role" "fis_role" {
  name               = "${var.project}-${var.environment}-fis-role"
  assume_role_policy = data.aws_iam_policy_document.fis_assume.json

  tags = local.tags
}

# IAM Policy: minimum permissions FIS needs to run this experiment
# StopTask - to inject the failure
# DescribeTasks/ListTasks - to find and target the right tasks
# DescribeAlarms - to evaluate the stop condition during the run
data "aws_iam_policy_document" "fis_permissions" {
  statement {
    actions = [
      "ecs:StopTask",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
    ]

    resources = ["*"]
  }
  statement {
    actions   = ["cloudwatch:DescribeAlarms"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "fis_policy" {
  name   = "${var.project}-${var.environment}-fis-policy"
  role   = aws_iam_role.fis_role.id
  policy = data.aws_iam_policy_document.fis_permissions.json
}

# FIS Experiment Template: stop one ECS task and observe recovery
# This verifies that ECS self-healing works and alarms fir as expected
resource "aws_fis_experiment_template" "ecs_task_stop" {
  description = "Stop one Fargate task - verify ECS replaces it and alarms fire and recover"
  role_arn    = aws_iam_role.fis_role.arn

  # Stop condition: if the SLO burn rate alarm fires during the experiment,
  # FIS aborts immediately - prevents the chaos run from consuming the error budget
  stop_condition {
    source = "aws:cloudwatch:alarm"
    value  = module.observability.burn_rate_alarm_arn
  }

  # Target: exactly one ECS task running in the Northwind cluster
  # COUNT(1) means FIS picks one task at random to stop
  target {
    name           = "northwind-ecs-tasks"
    resource_type  = "aws:ecs:task"
    selection_mode = "COUNT(2)"

    resource_tag {
      key   = "Project"
      value = var.project
    }
  }

  # Action: stop the selected task
  # ECS detects the missing task and launches a replacement automatically
  # This is the self-healing behavior we're testing
  action {
    name      = "stop-one-ecs-task"
    action_id = "aws:ecs:stop-task"
    target {
      key   = "Tasks"
      value = "northwind-ecs-tasks"
    }
  }

  tags = local.tags
}
