# Security Group
resource "aws_security_group" "app_server_sg" {
  name        = "${var.project_name}-app-server-sg"
  description = "Allow HTTP from VPC, all outbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP from within VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-app-server-sg"
    Project = var.project_name
  }
}

# IAM Role
resource "aws_iam_role" "app_server_role" {
  name = "${var.project_name}-app-server-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-app-server-role"
    Project = var.project_name
  }
}

# IAM Role Policy Attachment
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.app_server_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.app_server_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "app_server_instance_profile" {
  name = "${var.project_name}-app-server-instance-profile"
  role = aws_iam_role.app_server_role.name
}

# EC2 Instance
resource "aws_instance" "app_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_1_id
  vpc_security_group_ids = [aws_security_group.app_server_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.app_server_instance_profile.name
  monitoring             = true

  user_data = <<-EOF
#!/bin/bash
dnf update -y
dnf install -y amazon-ssm-agent amazon-cloudwatch-agent nginx
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
systemctl enable nginx
systemctl start nginx
EOF

  tags = {
    Name    = "${var.project_name}-app-server"
    Project = var.project_name
  }
}
