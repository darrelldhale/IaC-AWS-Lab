#!/bin/bash
set -euo pipefail
# This script is used to create an s3 bucket and a dynamodb table for terraform state locking

# ==================================================================
# Terraform Remote State Backend Setup
# Run once to create the S3 bucket and DynamoDB table for Terraform state management.
# ==================================================================

# Variables
ACCOUNT_ID="425924867120"
REGION="us-east-1"
BUCKET_NAME="sre-lab-tfstate-${ACCOUNT_ID}"
DYNAMODB_TABLE_NAME="sre-lab-tfstate-locking"

echo "==> Creating S3 bucket: ${BUCKET_NAME} in region: ${REGION}"
aws s3api create-bucket \
--bucket "${BUCKET_NAME}" \
--region "${REGION}"

echo "==> Enabling versioning on S3 bucket: ${BUCKET_NAME}"
aws s3api put-bucket-versioning \
--bucket "${BUCKET_NAME}" \
--versioning-configuration Status=Enabled

echo "==> Blocking public access to S3 bucket: ${BUCKET_NAME}"
cat > /tmp/public-access-block.json << EOF
{
  "BlockPublicAcls": true,
  "IgnorePublicAcls": true,
  "BlockPublicPolicy": true,
  "RestrictPublicBuckets": true
}
EOF
aws s3api put-public-access-block \
--bucket "${BUCKET_NAME}" \
--public-access-block configuration file:///tmp/public-access-block.json

echo "==> Creating DynamoDB table: ${DYNAMODB_TABLE_NAME} in region: ${REGION}"
aws dynamodb create-table \
--table-name "${DYNAMODB_TABLE_NAME}" \
--attribute-definitions AttributeName=LockID,AttributeType=S \
--key-schema AttributeName=LockID,KeyType=HASH \
--billing-mode PAY_PER_REQUEST \
--region "${REGION}"

echo ""
echo "==> Terraform remote state backend setup complete!"
echo "S3 Bucket: ${BUCKET_NAME}"
echo "DynamoDB Table: ${DYNAMODB_TABLE_NAME}"
echo "Region: ${REGION}"
echo ""

chmod +x ~/sre-lite-lab/month-3-iac/bootstrap/bootstrap.sh
