terraform {
  backend "s3" {
    bucket         = "aws-portfolio-terraform-state"
    key            = "04-text-to-speech-polly/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "aws-portfolio-terraform-locks"
    encrypt        = true

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
      project-no = "01"


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
  output_path = "${path.module}/04_lambda.zip"
}

# Random hex for unique bucket naming
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 bucket for audio files
resource "aws_s3_bucket" "polly_audio" {
  bucket        = "${var.s3_bucket_name}-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "polly_audio" {
  bucket = aws_s3_bucket.polly_audio.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "polly_audio_policy" {
  bucket = aws_s3_bucket.polly_audio.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.polly_audio.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.polly_audio]
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "polly-tts-lambda-role"

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
  name = "polly-tts-lambda-policy"
  role = aws_iam_role.lambda_role.id

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
          "polly:SynthesizeSpeech"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.polly_audio.arn}/*"
      }
    ]
  })
}

# Lambda function with conditional source
resource "aws_lambda_function" "polly_tts" {
  filename      = local.lambda_filename
  function_name = "${var.project_name}-polly-tts"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  timeout       = 30
  memory_size   = 256

  source_code_hash = local.lambda_source_hash

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.polly_audio.bucket
    }
  }

  lifecycle {
    ignore_changes = [source_code_hash, filename]
  }
}

# Lambda Function URL
resource "aws_lambda_function_url" "polly_tts_url" {
  function_name      = aws_lambda_function.polly_tts.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["POST"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["date", "keep-alive"]
    max_age           = 86400
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.polly_tts.function_name}"
  retention_in_days = 14
}
