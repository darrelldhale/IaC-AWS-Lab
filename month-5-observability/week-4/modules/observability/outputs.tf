output "http_5xx_alarm_name" {
  description = "Name of the 5xx error CloudWatch alarm"
  value = aws_cloudwatch_metric_alarm.http_5xx_too_high.alarm_name
}

output "http_4xx_filter_name" {
  description = "Name of the 4xx metric filter"
  value = aws_cloudwatch_log_metric_filter.http_4xx_count.name
}

output "http_5xx_filter_name" {
  description = "Name of the 5xx metric filter"
  value = aws_cloudwatch_log_metric_filter.http_5xx_count.name
}

output "request_count_filter_name" {
  description = "Name of the request count metric filter"
  value = aws_cloudwatch_log_metric_filter.http_requests.name
}

output "ecs_cpu_alarm_name" {
  description = "Name of the ECS CPU CloudWatch alarm"
  value = aws_cloudwatch_metric_alarm.ecs_cpu_too_high.alarm_name
}

output "ecs_memory_alarm_name" {
  description = "Name of the ECS memory CloudWatch alarm"
  value = aws_cloudwatch_metric_alarm.ecs_memory_too_high.alarm_name
}
