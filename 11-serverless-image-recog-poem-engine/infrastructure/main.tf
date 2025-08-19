# ===============================================
# AWS Serverless Image Recognition + Poetry Engine
# Project 11 - Portfolio Infrastructure
# ===============================================
#
# This project creates a serverless image recognition system that:
# 1. Accepts image uploads via Lambda Function URL
# 2. Stores images in S3 with automatic expiration
# 3. Triggers image analysis using AWS Rekognition
# 4. Generates creative poetry using AWS Bedrock
# 5. Stores generated poems back to S3
#
# Architecture Components:
# - S3 Bucket: Image storage with lifecycle policies
# - Lambda Functions: Upload handler and image processor
# - AWS Rekognition: Image analysis and label detection
# - AWS Bedrock: AI-powered poetry generation
# - CloudWatch: Logging and monitoring
#
# File Structure:
# - providers.tf: Terraform and AWS provider configuration
# - variables.tf: Input variables and configuration
# - locals.tf: Local values and computed expressions
# - s3.tf: S3 bucket and notification configuration
# - iam.tf: IAM roles and policies for Lambda
# - lambda.tf: Lambda functions and permissions
# - outputs.tf: Output values for integration
#
# Usage:
# terraform init
# terraform plan
# terraform apply
#
# Test Commands:
# aws s3 cp image.jpg s3://bucket-name/uploads/image.jpg
# aws s3 rm s3://bucket-name/uploads/image.jpg
# ===============================================