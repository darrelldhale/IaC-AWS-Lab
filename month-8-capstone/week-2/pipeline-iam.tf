# Dedicated IAM user for the GitHub Actions pipeline
# Scoped to exactly what the pipeline needs - no more
resource "aws_iam_user" "pipeline_user" {
  name = "github-actions-pipeline"
  tags = local.tags
}

# Policy with least-privilege permissions for each pipeline stage
resource "aws_iam_policy" "pipeline_policy" {
  name        = "sre-lab-github-actions-pipeline-policy"
  description = "Scoped permissions for the GitHub Actions CI/CD pipeline"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # ECR authentication — GetAuthorizationToken does not support
        # resource-level permissions, so * is required here
        Sid      = "ECRAuth"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        # ECR image push — scoped to the lab repo only
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
        # ECS task definition — describe existing, register new revision
        # These actions do not support resource-level scoping
        Sid    = "ECSTaskDefinition"
        Effect = "Allow"
        Action = [
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition"
        ]
        Resource = "*"
      },
      {
        # PassRole — required when registering a task definition
        # AWS verifies the caller can assign roles to ECS tasks
        # Scoped to sre-lab roles only — not all roles in the account
        Sid      = "PassRole"
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = "arn:aws:iam::425924867120:role/sre-lab-dev-*"
      },
      {
        # CodeDeploy — create and track blue/green deployments
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
