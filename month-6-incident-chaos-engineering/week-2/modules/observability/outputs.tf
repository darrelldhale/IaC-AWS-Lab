# === Output: HTTP 5xx Alarm Name ===
# Referenced in the root to wire alarm actions and used in CLI commands.
output "http_5xx_alarm_name" {
  description = "Name of the 5xx error CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.http_5xx_too_high.alarm_name
}

# === Output: HTTP 4xx Filter Name ===
# Identifies the metric filter watching for client errors in nginx logs.
output "http_4xx_filter_name" {
  description = "Name of the 4xx metric filter"
  value       = aws_cloudwatch_log_metric_filter.http_4xx_count.name
}

# === Output: HTTP 5xx Filter Name ===
# Identifies the metric filter watching for server errors in nginx logs.
output "http_5xx_filter_name" {
  description = "Name of the 5xx metric filter"
  value       = aws_cloudwatch_log_metric_filter.http_5xx_count.name
}

# === Output: Request Count Filter Name ===
# Identifies the metric filter counting all requests — used in SLI math.
output "request_count_filter_name" {
  description = "Name of the request count metric filter"
  value       = aws_cloudwatch_log_metric_filter.http_requests.name
}

# === Output: ECS CPU Alarm Name ===
# Referenced when describing alarm state via CLI.
output "ecs_cpu_alarm_name" {
  description = "Name of the ECS CPU CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.ecs_cpu_too_high.alarm_name
}

# === Output: ECS Memory Alarm Name ===
# Referenced when describing alarm state via CLI.
output "ecs_memory_alarm_name" {
  description = "Name of the ECS memory CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.ecs_memory_too_high.alarm_name
}

# === Output: SLO Burn Rate Alarm ARN ===
# Used as the FIS experiment stop condition — if burn rate goes critical
# during a chaos run, FIS uses this ARN to abort the experiment automatically.
output "burn_rate_alarm_arn" {
  description = "ARN of the SLO burn rate CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.slo_burn_rate_too_high.arn
}
