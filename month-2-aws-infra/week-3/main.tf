terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.aws_region
}

# SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"

  tags = {
    Name    = "${var.project_name}-alerts"
    Project = var.project_name
  }
}

# Email subscription to the SNS topic
resource "aws_sns_topic_subscription" "alert_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Look up the existing App Server
data "aws_instance" "app_server" {
  filter {
    name   = "tag:Name"
    values = ["sre-lab-app-server"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

# CloudWatch CPU Alarm
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Triggers when CPU exceeds 80% for 2 consecutive periods"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = data.aws_instance.app_server.id
  }
}

# CloudWatch Log Group for nginx logs
resource "aws_cloudwatch_log_group" "nginx" {
  name              = "/${var.project_name}/nginx/access"
  retention_in_days = 30

  tags = {
    Name    = "${var.project_name}-nginx-logs"
    Project = var.project_name
  }
}

# Metric filter - track HTTP 4xx errors from nginx logs
resource "aws_cloudwatch_log_metric_filter" "nginx_4xx" {
  name           = "${var.project_name}-nginx-4xx"
  pattern        = "[ip, id, user, timestamp, request, status_code=4*, size]"
  log_group_name = aws_cloudwatch_log_group.nginx.name

  metric_transformation {
    name      = "Nginx4xxErrors"
    namespace = "${var.project_name}/nginx"
    value     = "1"
  }
}

# Alarm on nginx 4xx errors
resource "aws_cloudwatch_metric_alarm" "nginx_4xx_high" {
  alarm_name          = "${var.project_name}-nginx-4xx-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Nginx4xxErrors"
  namespace           = "${var.project_name}/nginx"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Triggers when nginx 4xx errors exceed 10 in 60 seconds"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  tags = {
    Name    = "${var.project_name}-nginx-4xx-high"
    Project = var.project_name
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "CPU Utilization"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", data.aws_instance.app_server.id]
          ]
          period = 120
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Nginx 4xx Errors"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["${var.project_name}/nginx", "Nginx4xxErrors"]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type   = "alarm"
        x      = 0
        y      = 6
        width  = 24
        height = 3
        properties = {
          title = "Alarm Status"
          alarms = [
            aws_cloudwatch_metric_alarm.cpu_high.arn,
            aws_cloudwatch_metric_alarm.nginx_4xx_high.arn
          ]
        }
      }
    ]
  })
}
