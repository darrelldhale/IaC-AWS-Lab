#!/bin/bash

echo "========= Formatting Terraform Files ========="
terraform fmt
echo "Formatting Successful"
echo""
echo "========= Validating Terraform Files ========="
terraform validate
echo""
echo "========= Terraform Plan =============="
terraform plan

