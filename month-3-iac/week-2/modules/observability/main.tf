# SNS Topic
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"

  tags = {
    Name    = "${var.project_name}-alerts"
    Project = var.project_name
  }
}

resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "nginx_logs" {
  name              = "/${var.project_name}/nginx/access"
  retention_in_days = var.log_retention_days

  tags = {
    Name    = "${var.project_name}-nginx-logs"
    Project = var.project_name
  }
}

# CloudWatch Metric Filter for 4xx errors
resource "aws_cloudwatch_log_metric_filter" "nginx_4xx" {
  name           = "${var.project_name}-nginx-4xx"
  pattern        = "[ip, id, user, timestamp, request, status_code=4*, size]"
  log_group_name = aws_cloudwatch_log_group.nginx_logs.name

  metric_transformation {
    name      = "Nginx4xxErrors"
    namespace = "${var.project_name}/nginx"
    value     = "1"
  }
}

# CloudWatch CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm when CPU utilization exceeds 80% for 4 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.instance_id
  }
}

# CloudWatch Nginx 4xx Errors Alarm
resource "aws_cloudwatch_metric_alarm" "nginx_4xx_high" {
  alarm_name          = "${var.project_name}-nginx-4xx-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Nginx4xxErrors"
  namespace           = "${var.project_name}/nginx"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alarm when there are more than 10 4xx errors in a minute"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  tags = {
    Name    = "${var.project_name}-nginx-4xx-high-alarm"
    Project = var.project_name
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric",
        x      = 0,
        y      = 0,
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "InstanceId", var.instance_id]
          ],
          period = 120,
          stat   = "Average",
          region = var.aws_region,
          title  = "CPU Utilization"
        }
      },
      {
        type   = "metric",
        x      = 12,
        y      = 0,
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["${var.project_name}/nginx", "Nginx4xxErrors"]
          ],
          period = 60,
          stat   = "Sum",
          region = var.aws_region,
          title  = "Nginx 4xx Errors"
        }
      },
      { type   = "alarm",
        x      = 0,
        y      = 6,
        width  = 24,
        height = 3,
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


