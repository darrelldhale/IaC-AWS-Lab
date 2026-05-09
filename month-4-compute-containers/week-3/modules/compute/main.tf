# === ECR Repository ===
# Problem: ECS needs somewhere private to pull container images from.
# ECR is AWS's Docker container registry service.
resource "aws_ecr_repository" "ecr_repo" {
  name = "${var.project}-${var.environment}-ecr-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-ecr-repo" })
}

# === Security Group: ApplicationLoad Balancer ===
# Problem: Control what traffic can reach the ALB.
# Only port 80 from the internet allowed in.
resource "aws_security_group" "alb_sg" {
  name = "${var.project}-${var.environment}-alb-sg"
  description = "Allows HTTP from the internet to the ALB"
  vpc_id = var.vpc_id

  ingress {
    description = "HTTP from Internet"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-alb-sg" })
}

# === Security Group: Fargate Tasks ===
# Problem: Fargate tasks should only accept traffic from the ALB, never directly from the internet.
# Allow traffic from the ALB only.
resource "aws_security_group" "ecs_tasks_sg" {
  name = "${var.project}-${var.environment}-ecs-tasks-sg"
  description = "Allow traffic from ALB to ECS Fargate tasks"
  vpc_id = var.vpc_id

  ingress {
    description = "Allow HTTP traffic from ALB"
    from_port = var.container_port
    to_port = var.container_port
    protocol = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-ecs-tasks-sg" })
}

# === IAM Role ECS Task Execution Role ===
# Problem: ECS tasks need permissions to pull images from ECR and send.
# container logs to CloudWatch. This role grants those permissions to the
# ECS service itself, not your application code.
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project}-${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-ecs-task-execution-role" })
}

# === IAM Policy Attachment: ECS Task Execution Role Policy ===
# Problem: Grants the execution role permission to pull from ECR and write to CloudWatch.
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# === IAM Role: ECS Task Role ===
# Problem: Your application code running in the ECS task needs permission to interact with other AWS services.
# For example, if you were using SQS or S3, you would add policies here. This role
# is what your running container assumes - what the app itself is allowed to do in AWS.
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project}-${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-ecs-task-role" })
}

# === IAM Policy: ECS Exec Policy ===
# Problem: Without this, you can't shell into a running Fargate task.
# ECS Exec is the container equivalent of SSM Session Manager.
# This policy grants the task permission to open that channel.
resource "aws_iam_role_policy" "ecs_exec_policy" {
  name = "${var.project}-${var.environment}-ecs-exec-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
        ]
        Resource = "*"
      }
    ]
  })
}

# === Application Load Balancer ===
# Problem: Need a load balancer to distribute traffic to our Fargate tasks.
# ALB allows us to use path-based routing.
resource "aws_lb" "app_load_balancer" {
  name = "${var.project}-${var.environment}-app-load-balancer"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb_sg.id]
  subnets = var.public_subnet_ids

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-app-load-balancer" })
}

# === Target Group ===
# Problem: ECS needs to register and deregister Fargate task IPs dynamically.
# target_type = "ip" is required for Fargate — unlike EC2 which uses instance IDs,
# Fargate tasks register by their private IP address.
resource "aws_lb_target_group" "app_target_group" {
  name = "${var.project}-${var.environment}-app-target-group"
  port = var.container_port
  protocol = "HTTP"
  target_type = "ip"
  vpc_id = var.vpc_id

  health_check {
    path = "/"
    matcher = "200-399"
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    interval = 30
  }

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-app-target-group" })
}

# === ALB Listener ===
# Problem: The ALB needs to know what to do when it receives traffic.
# This rule says: "If you get HTTP traffic, forward it to the target group we created above."
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_load_balancer.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.app_target_group.arn
  }
}

# === CloudWatch Log Group ===
# Problem: Containers write logs to stdout/stderr but those disappear when the task stops.
# This log group gives those logs a permanent home in CloudWatch so you can
# read them after the fact — essential for troubleshooting crashed tasks.
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "/ecs/${var.project}/${var.environment}"
  retention_in_days = 7

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-ecs-log-group" })
}

# === ECS Cluster ===
# Problem: ECS needs a logical boundary to group and manage your tasks and services.
# The cluster itself doesn't run anything — it's the namespace that holds everything together.
# Think of it like the VPC of the container world.
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.project}-${var.environment}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-ecs-cluster" })
}

# === ECS Task Definition ===
# Problem: ECS needs a blueprint that defines exactly how to run your container.
# Which image to use, how much CPU and memory, which ports to expose,
# where to send logs, and which IAM roles to use.
# This is the direct equivalent of a Launch Template in EC2.
resource "aws_ecs_task_definition" "ecs_task_definition" {
  family = "${var.project}-${var.environment}-ecs-task"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = var.task_cpu
  memory = var.task_memory
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([
    {
      name = "${var.project}-${var.environment}-ecs-container"
      image = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          protocol = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = aws_cloudwatch_log_group.ecs_log_group.name
          awslogs-region = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-ecs-task-definition" })
}

# === ECS Service ===
# Problem: A task definition alone doesn't run anything — it's just a blueprint.
# The ECS service is what actually runs your tasks, keeps the desired count healthy,
# restarts failed tasks automatically, and registers them with the ALB.
# This is the direct equivalent of an Auto Scaling Group in EC2.
resource "aws_ecs_service" "ecs_service" {
  name = "${var.project}-${var.environment}-ecs-service"
  cluster = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  desired_count = var.desired_count
  launch_type = "FARGATE"
  enable_execute_command = true

  load_balancer {
    target_group_arn = aws_lb_target_group.app_target_group.arn
    container_name = "${var.project}-${var.environment}-ecs-container"
    container_port = var.container_port
  }

  network_configuration {
    subnets = var.private_subnet_ids
    security_groups = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-ecs-service" })
}


