output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector"
  value       = aws_guardduty_detector.main.id
}

output "config_s3_bucket_name" {
  description = "Name of the S3 bucket receiving Config history"
  value       = aws_s3_bucket.config_history.bucket
}

output "securityhub_standards_arn" {
  description = "ARN of the Security Hub standards subscription"
  value       = aws_securityhub_standards_subscription.fsbp.id
}
