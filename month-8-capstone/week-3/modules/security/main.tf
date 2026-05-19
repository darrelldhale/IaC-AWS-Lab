# -------------------------------------------------------
# AWS GUARDDUTY
# Enables threat detection for the account.
# Monitors CloudTrail, VPC Flow Logs, and DNS logs.
# Generates findings when suspicious activity is detected.
# ----------

resource "aws_guardduty_detector" "main" {
  enable = true

tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-guardduty"
  })
}

# -------------------------------------------------------
# AWS CONFIG — S3 BUCKET
# Config delivers configuration history and snapshots here.
# Account ID in the name guarantees global uniqueness.
# -------------------------------------------------------

resource "aws_s3_bucket" "config_history" {
  bucket = "${var.project}-${var.environment}-config-history-${var.aws_account_id}"
  force_destroy = true

tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-guardduty"
  })
}

resource "aws_s3_bucket_versioning" "config_history" {
  bucket = aws_s3_bucket.config_history.id

  versioning_configuration {
   status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config_history" {
  bucket = aws_s3_bucket.config_history.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "config_history" {
  bucket =  aws_s3_bucket.config_history.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

# -------------------------------------------------------
# AWS CONFIG — S3 BUCKET POLICY
# Grants the Config service permission to write history
# files into this bucket. Without this, Config will fail
# to deliver and the recorder will report errors.
# -------------------------------------------------------

resource "aws_s3_bucket_policy" "config_history" {
  bucket = aws_s3_bucket.config_history.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowConfigBucketCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = "arn:aws:s3:::${aws_s3_bucket.config_history.bucket}"
      },
      {
        Sid    = "AllowConfigDelivery"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::${aws_s3_bucket.config_history.bucket}/AWSLogs/${var.aws_account_id}/Config/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# -------------------------------------------------------
# AWS CONFIG — IAM ROLE
# Config assumes this role to describe and record
# resource configurations across your account.
# AWSConfigRole is the AWS-managed policy that grants
# exactly the read permissions Config needs.
# -------------------------------------------------------

resource "aws_iam_role" "config" {
  name = "${var.project}-${var.environment}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-guardduty"
  })
}

resource "aws_iam_role_policy" "config" {
  name = "${var.project}-${var.environment}-config-policy"
  role = aws_iam_role.config.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ConfigS3Delivery"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl"
        ]
        Resource = [
          aws_s3_bucket.config_history.arn,
          "${aws_s3_bucket.config_history.arn}/*"
        ]
      },
      {
        Sid      = "ConfigReadAccess"
        Effect   = "Allow"
        Action   = ["config:*", "ec2:Describe*", "iam:Get*", "iam:List*", "s3:GetBucket*", "s3:ListAllMyBuckets"]
        Resource = "*"
      }
    ]
  })
}

# -------------------------------------------------------
# AWS CONFIG — RECORDER
# Defines what Config records. ALL_SUPPORTED_RESOURCES
# tells Config to track every resource type it supports
# in this region.
# -------------------------------------------------------

resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project}-${var.environment}-config-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# -------------------------------------------------------
# AWS CONFIG — DELIVERY CHANNEL
# Tells Config to deliver history files to the S3 bucket.
# depends_on ensures the recorder exists before the
# delivery channel is created.
# -------------------------------------------------------

resource "aws_config_delivery_channel" "main" {
  name           = "${var.project}-${var.environment}-config-delivery"
  s3_bucket_name = aws_s3_bucket.config_history.bucket

  depends_on = [aws_config_configuration_recorder.main]
}

# -------------------------------------------------------
# AWS CONFIG — RECORDER STATUS
# The on switch. Without this, the recorder and delivery
# channel exist but Config records nothing.
# -------------------------------------------------------

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}

# -------------------------------------------------------
# AWS CONFIG RULE — RESTRICTED SSH
# Checks all security groups for unrestricted inbound
# access on port 22. Flags NON_COMPLIANT if any security
# group allows SSH from 0.0.0.0/0 or ::/0.
# This is an AWS managed rule — no custom code needed.
# -------------------------------------------------------

resource "aws_config_config_rule" "restricted_ssh" {
  name = "${var.project}-${var.environment}-restricted-ssh"

  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }

  depends_on = [aws_config_configuration_recorder_status.main]

tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-guardduty"
  })
}


# -------------------------------------------------------
# SECURITY HUB
# Aggregates findings from GuardDuty and Config into
# a single pane. Also runs its own checks against the
# AWS Foundational Security Best Practices standard.
# GuardDuty and Config findings flow in automatically
# once Security Hub is enabled — no extra wiring needed.
# -------------------------------------------------------

resource "aws_securityhub_account" "main" {
  depends_on = [aws_guardduty_detector.main]
}

resource "aws_securityhub_standards_subscription" "fsbp" {
  standards_arn = "arn:aws:securityhub:${var.aws_region}::standards/aws-foundational-security-best-practices/v/1.0.0"

  depends_on = [aws_securityhub_account.main]
}
