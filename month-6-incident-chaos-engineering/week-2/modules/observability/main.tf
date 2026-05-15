# Local Tags
locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(var.tags, {
    Module = "observability"
  })
}

data "aws_region" "current" {}

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

  # Notify the SNS alerts topic when the alarm fires
  alarm_actions = [aws_sns_topic.alerts.arn]

  # Also notify when the alarm returns to normal - confirms the issue resolved
  ok_actions = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}

# Alarm: SLO burn rate too high
# Uses metric math — watches an expression, not a single metric
# m1 = total requests, m2 = 5xx errors
# e1 = (5xx rate) / 0.005 — burn rate relative to the 0.5% SLO error budget
# return_data = true tells CloudWatch which expression to evaluate the threshold against
# Fires when burn rate exceeds 14.4 — budget exhausted in under 1 hour at current rate
resource "aws_cloudwatch_metric_alarm" "slo_burn_rate_too_high" {
  alarm_name          = "${local.name_prefix}-slo-burn-rate-too-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  threshold           = "14.4"
  alarm_description   = "SLO burn rate exceeds 14.4x — error budget exhausted within 1 hour"
  treat_missing_data  = "notBreaching"

  # Expression: burn rate relative to allowed 0.5% error rate
  metric_query {
    id          = "e1"
    expression  = "IF(m1>0, (m2/m1)/0.005, 0)"
    label       = "Burn Rate"
    return_data = true
  }

  # Input: total request count
  metric_query {
    id = "m1"
    metric {
      metric_name = "HttpRequestCount"
      namespace   = "SRELab/Nginx"
      period      = 300
      stat        = "Sum"
    }
  }

  # Input: 5xx error count
  metric_query {
    id = "m2"
    metric {
      metric_name = "Http5xxCount"
      namespace   = "SRELab/Nginx"
      period      = 300
      stat        = "Sum"
    }
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}

# SNS Topic: the central notification channel for all Northwind
# infrastructure alerts. Every alarm in this module will publish to this topic
resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"

  tags = local.common_tags
}

# SNS Subscription: delivers alarm notifications to on-call email address
# AWS will send a confirmation email - the subscription is inactive until confirmed
resource "aws_sns_topic_subscription" "alert_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Alarm: ECS CPU utilization too high
# Fires when average CPU across all tasks exceeds 80% for 2 consecutive minutes
# High CPU causes request slowdowns and eventual task crashes
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_too_high" {
  alarm_name          = "${local.name_prefix}-ecs-cpu-too-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "ECS cluster CPU over 80% for 2 minutes"
  treat_missing_data = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}

#Alarm: ECS Memory utilization too high
# Fires when average memory across all tasks exceeds 80% for 2 consecutive minutes
# memory exhaustion causes ECS to kill and restart tasks - visible as 5xx errors
resource "aws_cloudwatch_metric_alarm" "ecs_memory_too_high" {
  alarm_name          = "${local.name_prefix}-ecs-memory-too-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "ECS cluster memory over 80% for 2 minutes"
  treat_missing_data = "notBreaching"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}

# Data source: pulls our AWS account ID so the bucket name is globally unique
data "aws_caller_identity" "current" {}

# S3 Bucket: stores canary screenshots and logs after each run
# force_destroy = true because these are throwaway artifacts - ok to wipe on destroy
resource "aws_s3_bucket" "canary_results" {
  bucket = "${local.name_prefix}-canary-results-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
  tags = local.common_tags
}

# Block all public access - canary artifacts are internal diagnostic data only
resource "aws_s3_bucket_public_access_block" "canary_results" {
  bucket = aws_s3_bucket.canary_results.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM role: the canary Lambda function runs as this role
# The assume role policy tells AWS that Lambda is allowed to use it
data "aws_iam_policy_document" "canary_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "canary_role" {
  name = "${local.name_prefix}-canary-role"
  assume_role_policy = data.aws_iam_policy_document.canary_assume.json

  tags = local.common_tags
}

# IAM policy: three permissions the canary needs to do its jo
data "aws_iam_policy_document" "canary_permissions" {

  # Permission 1: write screenshots and logs to the artifacts bucket
  statement {
    actions = [ "s3:PutObject", "s3:GetBucketLocation" ]
    resources = [
      aws_s3_bucket.canary_results.arn,
      "${aws_s3_bucket.canary_results.arn}/*"
]
}

  # Permission 2: publish pass/fail metrics to CloudWatch
  # Scoped to the CloudWatchSynthetics namespace only — not all of CloudWatch
  statement {
    actions = [ "cloudwatch:PutMetricData" ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["CloudWatchSynthetics"]
    }
  }

  # Permission 3: write canary execution logs to CloudWatch Logs
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

# Attach the policy to the role
resource "aws_iam_role_policy" "canary_policy" {
  name = "${local.name_prefix}-canary-policy"
  role = aws_iam_role.canary_role.id
  policy = data.aws_iam_policy_document.canary_permissions.json
}

# Zip the canary script at plan time with the live ALB DNS name injected
# templatefile reads canary.js.tftpl and replaces ${alb_dns_name} with the real value
# Lambda requires the nodejs/node_modules/ directory structure inside the zip
data "archive_file" "canary_script" {
  type = "zip"
  output_path = "${path.module}/canary.zip"

  source {
    content = templatefile("${path.module}/canary.js.tftpl", {
      alb_dns_name = var.alb_dns_name
    })
    filename = "nodejs/node_modules/canary.js"
  }
}

# CloudWatch Synthetics Canary: runs the canary script every minute and hits the ALB
resource "aws_synthetics_canary" "northwind_patient_portal" {
  name = "${local.name_prefix}-canary"
  artifact_s3_location = "s3://${aws_s3_bucket.canary_results.bucket}/canary/"
  execution_role_arn = aws_iam_role.canary_role.arn
  handler = "canary.handler"
  zip_file = data.archive_file.canary_script.output_path
  runtime_version = "syn-nodejs-puppeteer-9.1"
  start_canary = true

  schedule {
    # Minimum interval for Cloudwatch Synthetics is 1 minute
    expression = "rate(1 minute)"
  }

  tags = local.common_tags
}

# Alarm: fires when the canary fails two consecutive one-minute checks
# LessThanThreshold because we want 100% success — any drop is a problem
# treat_missing_data = breaching — silence from the canary is itself a failure signal
resource "aws_cloudwatch_metric_alarm" "canary_failed" {
  alarm_name          = "${local.name_prefix}-canary-failed"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "SuccessPercent"
  namespace           = "CloudWatchSynthetics"
  period              = "60"
  statistic           = "Average"
  threshold           = "100"
  alarm_description   = "Patient Portal canary failed 2 consecutive checks — service may be down"
  treat_missing_data  = "breaching"

  dimensions = {
    CanaryName = aws_synthetics_canary.northwind_patient_portal.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}


# CloudWatch Dashboard — Northwind Health Group on-call view
# Single pane of glass showing HTTP health and ECS resource utilization
# Designed to answer the first question during an incident: where is the problem?
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [

      # ── Row 1: Alarm status ─────────────────────────────────────────
      {
        type   = "alarm"
        x      = 0
        y      = 0
        width  = 24
        height = 3
        properties = {
          title = "Northwind Health Group — Active Alarms"
          alarms = [
            aws_cloudwatch_metric_alarm.http_5xx_too_high.arn,
            aws_cloudwatch_metric_alarm.ecs_cpu_too_high.arn,
            aws_cloudwatch_metric_alarm.ecs_memory_too_high.arn,
            aws_cloudwatch_metric_alarm.slo_burn_rate_too_high.arn,
            aws_cloudwatch_metric_alarm.canary_failed.arn
          ]
        }
      },

      # ── Row 2: HTTP metrics ──────────────────────────────────────────
      {
        type   = "metric"
        x      = 0
        y      = 3
        width  = 8
        height = 6
        properties = {
          title   = "Request Rate"
          region  = data.aws_region.current.name
          view    = "timeSeries"
          period  = 60
          stat    = "Sum"
          metrics = [
            ["SRELab/Nginx", "HttpRequestCount"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 3
        width  = 8
        height = 6
        properties = {
          title   = "4xx Errors"
          region  = data.aws_region.current.name
          view    = "timeSeries"
          period  = 60
          stat    = "Sum"
          metrics = [
            ["SRELab/Nginx", "Http4xxCount"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 3
        width  = 8
        height = 6
        properties = {
          title   = "5xx Errors"
          region  = data.aws_region.current.name
          view    = "timeSeries"
          period  = 60
          stat    = "Sum"
          metrics = [
            ["SRELab/Nginx", "Http5xxCount"]
          ]
        }
      },

      # ── Row 3: ECS resource health ───────────────────────────────────
      {
        type   = "metric"
        x      = 0
        y      = 9
        width  = 12
        height = 6
        properties = {
          title   = "ECS CPU Utilization"
          region  = data.aws_region.current.name
          view    = "timeSeries"
          period  = 60
          stat    = "Average"
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 9
        width  = 12
        height = 6
        properties = {
          title   = "ECS Memory Utilization"
          region  = data.aws_region.current.name
          view    = "timeSeries"
          period  = 60
          stat    = "Average"
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name]
          ]
        }
      },

      # ── Row 4: SLO health ────────────────────────────────────────────

      # SLI: live success rate calculated from metric math
      # Formula: (total requests - 5xx errors) / total requests * 100
      # IF guard prevents division by zero when traffic is zero
      # Red annotation line marks the 99.5% SLO target
      {
        type   = "metric"
        x      = 0
        y      = 15
        width  = 8
        height = 6
        properties = {
          title  = "SLI — Success Rate %"
          region = data.aws_region.current.name
          view   = "timeSeries"
          period = 300
          metrics = [
            [{ expression = "IF(m1>0, ((m1-m2)/m1)*100, 100)", label = "Success Rate %", id = "e1" }],
            ["SRELab/Nginx", "HttpRequestCount", { id = "m1", visible = false, stat = "Sum", period = 300 }],
            ["SRELab/Nginx", "Http5xxCount", { id = "m2", visible = false, stat = "Sum", period = 300 }]
          ]
          annotations = {
            horizontal = [
              { value = 99.5, label = "SLO Target — 99.5%", color = "#ff6961" }
            ]
          }
          yAxis = {
            left = { min = 95, max = 100 }
          }
        }
      },

      # Burn rate: how fast we are consuming the error budget
      # Formula: (5xx rate) / 0.005 — where 0.005 is the allowed 0.5% error rate
      # 1.0 = on pace to exactly exhaust budget in 30 days
      # 14.4 = budget exhausted in 1 hour (fast burn threshold)
      # 6.0  = budget exhausted in ~5 days (slow burn threshold)
      {
        type   = "metric"
        x      = 8
        y      = 15
        width  = 8
        height = 6
        properties = {
          title  = "Burn Rate (1.0 = on pace)"
          region = data.aws_region.current.name
          view   = "timeSeries"
          period = 300
          metrics = [
            [{ expression = "IF(m1>0, (m2/m1)/0.005, 0)", label = "Burn Rate", id = "e1" }],
            ["SRELab/Nginx", "HttpRequestCount", { id = "m1", visible = false, stat = "Sum", period = 300 }],
            ["SRELab/Nginx", "Http5xxCount", { id = "m2", visible = false, stat = "Sum", period = 300 }]
          ]
          annotations = {
            horizontal = [
              { value = 14.4, label = "Fast Burn — budget gone in 1hr", color = "#ff6961" },
              { value = 6,    label = "Slow Burn — budget gone in 5d",  color = "#ff9900" }
            ]
          }
          yAxis = {
            left = { min = 0 }
          }
        }
      },

      # Static SLO reference card — burn rate thresholds and actions
      # No metric data — this is a reference for the on-call engineer
      {
        type   = "text"
        x      = 16
        y      = 15
        width  = 8
        height = 6
        properties = {
          markdown = "## SLO Reference\n**Target:** 99.5% success rate (30-day window)\n**Error Budget:** 0.5% of requests may fail\n\n| Burn Rate | Action |\n|---|---|\n| < 1.0 | Healthy — deploy freely |\n| 1.0 – 6.0 | Monitor closely |\n| > 6.0 | Investigate — slow burn |\n| > 14.4 | **Page on-call immediately** |"
        }
      }
    ]
  })
}
