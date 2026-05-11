locals {
  name_prefix = "${var.prefix}-${var.environment}"

  common_tags = merge(var.tags, {
    Module = "observability"
  })
}

# Metric Filter: counts every HTTP 5xx response
# Reads from the JSON log field "status"
resource "aws_cloudwatch_log_metric_filter" "http_5xx_count" {
  name           = "${local.name_prefix}-http-5xx-count"
  pattern        = "{$.status=*5*}"
  log_group_name = var.log_group_name

  metric_transformation {
    name      = "Http5xxCount"
    namespace = "SRELab/Nginx"
    value     = "1"
    unit      = "Count"
  }
}

# Metric Filter: counts every HTTP 4xx response
# Catches 404s, 403s, bad requests,etc.
resource "aws_cloudwatch_log_metric_filter" "http_4xx_count" {
  name           = "${local.name_prefix}-http-4xx-count"
  pattern        = "{$.status=*4*}"
  log_group_name = var.log_group_name

  metric_transformation {
    name      = "Http4xxCount"
    namespace = "SRELab/Nginx"
    value     = "1"
    unit      = "Count"
  }
}

# Metric Filter: counts every request regardless of status
# Used to calculate total request rate on the dashboard
resource "aws_cloudwatch_log_metric_filter" "http_requests" {
  name           = "${local.name_prefix}-http-request-count"
  pattern        = "{$.status=*}"
  log_group_name = var.log_group_name

  metric_transformation {
    name      = "HttpRequestCount"
    namespace = "SRELab/Nginx"
    value     = "1"
    unit      = "Count"
  }
}

# Metric Alarm: fires when 5xx errors exceed threshold
# This is the alarm the on-call engineer would wake up to
resource "aws_cloudwatch_metric_alarm" "http_5xx_too_high" {
  alarm_name          = "${local.name_prefix}-http-5xx-too-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Http5xxCount"
  namespace           = "SRELab/Nginx"
  period              = "60"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "More than 5 HTTP 5xx errors in 60 seconds"
  treat_missing_data = "notBreaching"

  tags = local.common_tags
}
