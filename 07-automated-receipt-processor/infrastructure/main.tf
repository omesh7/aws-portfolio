terraform {
  backend "s3" {
    bucket         = "aws-portfolio-terraform-state"
    key            = "07-automated-receipt-processor/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "aws-portfolio-terraform-locks"
    encrypt        = true
    use_lockfile   = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project    = var.project_name
      project-no = "07"
    }
  }
}

# Environment-based lambda packaging
locals {
  use_local_archive  = var.environment == "local"
  lambda_filename    = local.use_local_archive ? data.archive_file.lambda_zip[0].output_path : var.lambda_zip_path
  lambda_source_hash = local.use_local_archive ? data.archive_file.lambda_zip[0].output_base64sha256 : (fileexists(var.lambda_zip_path) ? filebase64sha256(var.lambda_zip_path) : "")
}

# Conditional archive - only for local development
data "archive_file" "lambda_zip" {
  count       = local.use_local_archive ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/07_lambda.zip"
}

# Random hex for unique resource naming
resource "random_id" "resource_suffix" {
  byte_length = 4
}

# S3 bucket for receipt uploads
resource "aws_s3_bucket" "uploads_bucket" {
  bucket        = "${var.s3_bucket_name}-${random_id.resource_suffix.hex}"
  force_destroy = true
}

# DynamoDB table for receipts
resource "aws_dynamodb_table" "receipts_table" {
  name         = "${var.dynamodb_table_name}-${random_id.resource_suffix.hex}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "receipt_id"
  range_key    = "date"

  attribute {
    name = "receipt_id"
    type = "S"
  }

  attribute {
    name = "date"
    type = "S"
  }
}

# SNS topic for notifications
resource "aws_sns_topic" "receipt_notifications" {
  name         = "ReceiptNotifications-${var.project_name}"
  display_name = "Receipt Processing Notifications"
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "lambda-receipt-processor-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "receipt-processor-lambda-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "textract:AnalyzeDocument",
          "textract:DetectDocumentText"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.uploads_bucket.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.receipts_table.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.receipt_notifications.arn
      }
    ]
  })
}

# Lambda function
resource "aws_lambda_function" "process_receipt" {
  filename      = local.lambda_filename
  function_name = "${var.project_name}-receipt-processor"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 180
  memory_size   = 256

  source_code_hash = local.lambda_source_hash

  environment {
    variables = {
      DYNAMODB_TABLE          = aws_dynamodb_table.receipts_table.name
      NOTIFICATION_LOG_BUCKET = aws_s3_bucket.uploads_bucket.bucket
      SNS_TOPIC_ARN           = aws_sns_topic.receipt_notifications.arn
    }
  }

  lifecycle {
    ignore_changes = [source_code_hash, filename]
  }
}

# Lambda Function URL
resource "aws_lambda_function_url" "process_receipt_url" {
  function_name      = aws_lambda_function.process_receipt.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["GET", "POST"]
    allow_headers     = ["date", "keep-alive", "content-type"]
    expose_headers    = ["date", "keep-alive"]
    max_age           = 86400
  }
}

# S3 bucket notification
resource "aws_s3_bucket_notification" "receipt_upload_notification" {
  bucket = aws_s3_bucket.uploads_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.process_receipt.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "receipts/"
    filter_suffix       = ".pdf"
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}

# Lambda permission for S3
resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_receipt.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.uploads_bucket.arn
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.process_receipt.function_name}"
  retention_in_days = 14
}

# Outputs
output "lambda_function_url" {
  value       = aws_lambda_function_url.process_receipt_url.function_url
  description = "Lambda function URL"
}

output "lambda_function_name" {
  value       = aws_lambda_function.process_receipt.function_name
  description = "Lambda function name"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.uploads_bucket.bucket
  description = "S3 bucket name for receipt uploads"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.receipts_table.name
  description = "DynamoDB table name"
}

output "sns_topic_arn" {
  value       = aws_sns_topic.receipt_notifications.arn
  description = "SNS topic ARN"
}