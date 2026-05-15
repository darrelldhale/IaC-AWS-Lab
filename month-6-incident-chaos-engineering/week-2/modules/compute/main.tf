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

  ingress {
    description = "Test listener for green target group"
    from_port = 8080
    to_port = 8080
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

# === Target Group: Blue (Live Version) ===
# Problem: Blue/green needs two separate target groups so CodeDeploy
# can swap between them seamlessly. Blue starts as the live target group.
resource "aws_lb_target_group" "blue_target_group" {
  name = "${var.project}-${var.environment}-blue-target-group"
  port = var.container_port
  protocol = "HTTP"
  vpc_id = var.vpc_id
  target_type = "ip"

  health_check {
    path = "/"
    matcher = "200-399"
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    interval = 30
  }

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-blue-target-group" })
}

# === Target Group: Green (New Version) ===
# Problem: CodeDeploy deploys new tasks here first before shifting traffic.
# Having a separate green group prevents downtime during deployments. Zero
# users hit the new version until the traffic shift is approved.
resource "aws_lb_target_group" "green_target_group" {
  name = "${var.project}-${var.environment}-green-target-group"
  port = var.container_port
  protocol = "HTTP"
  vpc_id = var.vpc_id
  target_type = "ip"

  health_check {
    path = "/"
    matcher = "200-399"
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    interval = 30
  }

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-green-target-group" })
}


# === ALB Listener: Production (Port 80) ===
# Problem: This is the live listener that serves real user traffic.
# CodeDeploy controls which target group this points to during deployments.
# It starts pointing at blue, switches to green after a successful deployment.
resource "aws_lb_listener" "blue_http" {
  load_balancer_arn = aws_lb.app_load_balancer.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.blue_target_group.arn
  }

  lifecycle {
    ignore_changes = [ default_action ]
  }
}

# === ALB Listener: Test (Port 8080) ===
# Problem: Before shifting real traffic, you need a way to test the green
# environment directly. This listener lets you hit green on port 8080
# to verify it works before CodeDeploy shifts production traffic.
resource "aws_lb_listener" "green_http" {
  load_balancer_arn = aws_lb.app_load_balancer.arn
  port = 8080
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.green_target_group.arn
  }

  lifecycle {
    ignore_changes = [ default_action ]
  }
}



# === CloudWatch Log Group ===
# Problem: Containers write logs to stdout/stderr but those disappear when the task stops.
# This log group gives those logs a permanent home in CloudWatch so I can
# read them after the fact — essential for troubleshooting crashed tasks.
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "/ecs/${var.project}/${var.environment}"
  retention_in_days = 7

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-ecs-log-group" })
}

# === ECS Cluster ===
# Problem: ECS needs a logical boundary to group and manage my tasks and services.
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
  propagate_tags         = "SERVICE"

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue_target_group.arn
    container_name = "${var.project}-${var.environment}-ecs-container"
    container_port = var.container_port
  }

  network_configuration {
    subnets = var.private_subnet_ids
    security_groups = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  lifecycle {
    ignore_changes = [ task_definition, load_balancer ]
  }

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-ecs-service" })
}

# === IAM Role: CodeDeploy ===
# Problem: CodeDeploy needs permissions to manage ECS services and update the ALB target groups.
# This role grants those permissions so it can orchestrate blue/green deployments.
resource "aws_iam_role" "codedeploy_role" {
  name = "${var.project}-${var.environment}-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-codedeploy-role" })
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

# === CodeDeploy Application ===
# Problem: CodeDeploy needs a named application as a container for my
# deployment configuration. Think of it as the project that groups all
# deployment activity together.
resource "aws_codedeploy_app" "codedeploy_app" {
  name = "${var.project}-${var.environment}-codedeploy-app"
  compute_platform = "ECS"

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-codedeploy-app" })
}

# === CodeDeploy Deployment Group ===
# Problem: This is where the magic happens. The deployment group ties together
# the ECS service, both target groups, the ALB, and the CodeDeploy role.
# It defines how the blue/green deployment should work — which target groups
# to use, how to shift traffic, and who has permission to deploy. And also,
# when old tasks are terminated.
resource "aws_codedeploy_deployment_group" "codedeploy_deployment_group" {
  app_name = aws_codedeploy_app.codedeploy_app.name
  deployment_group_name = "${var.project}-${var.environment}-codedeploy-deployment-group"
  service_role_arn = aws_iam_role.codedeploy_role.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  auto_rollback_configuration {
    enabled = true
    events = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action = "TERMINATE"
      termination_wait_time_in_minutes = var.deployment_wait_time
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.ecs_cluster.name
    service_name = aws_ecs_service.ecs_service.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.blue_http.arn]
      }

      test_traffic_route {
        listener_arns = [aws_lb_listener.green_http.arn]
      }

      target_group {
        name = aws_lb_target_group.blue_target_group.name
      }

      target_group {
        name = aws_lb_target_group.green_target_group.name
      }
    }
  }

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-codedeploy-deployment-group" })
}

