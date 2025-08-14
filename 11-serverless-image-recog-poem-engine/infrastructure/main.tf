# -------------------------------
# Terraform Configuration
# -------------------------------
terraform {
  cloud {
    organization = "aws-portfolio-omesh"
    workspaces {
      name = "11-serverless-image-recog-poem-engine"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# -------------------------------
# Provider Configuration
# -------------------------------
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# -------------------------------
# Locals
# -------------------------------
locals {
  bucket_name_prefix = "${var.project_name}-bucket"
  uploads_prefix     = "uploads/"
  poems_prefix       = "poems/"
  lambda_env_vars = {
    ENVIRONMENT      = "Portfolio"
    LOG_LEVEL        = "INFO"
    BUCKET_NAME      = "${var.project_name}-bucket"
    BEDROCK_MODEL_ID = var.bedrock_model_id
  }


  lambda_memory   = 128
  expiration_days = 1
}

# -------------------------------
# S3 Bucket Configuration
# -------------------------------
resource "aws_s3_bucket" "main" {
  bucket        = local.bucket_name_prefix
  force_destroy = true
}

# Lifecycle rule to auto-expire objects in the uploads folder
resource "aws_s3_bucket_lifecycle_configuration" "uploads_expiration" {
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "expire-uploads-after-5min"
    status = "Enabled"

    filter {
      prefix = local.uploads_prefix
    }

    expiration {
      days = local.expiration_days
    }
  }
}

# Create S3 folders by creating zero-byte objects
resource "aws_s3_object" "uploads_folder" {
  bucket        = aws_s3_bucket.main.bucket
  key           = local.uploads_prefix
  force_destroy = true
}

resource "aws_s3_object" "poems_folder" {
  bucket        = aws_s3_bucket.main.bucket
  key           = local.poems_prefix
  force_destroy = true
}

# -------------------------------
# IAM Policy for Lambda
# -------------------------------
resource "aws_iam_policy" "lambda_s3_rekognition_logs" {
  name        = "${var.project_name}-lambda_s3_rekognition_logging"
  description = "Allows Lambda access to S3, Rekognition, and CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "rekognition:DetectText",
          "rekognition:DetectLabels",
          "rekognition:GetLabelDetection",
          "rekognition:RecognizeCelebrities",
          "rekognition:DetectCustomLabels",
          "rekognition:DetectModerationLabels",
          "rekognition:ListDatasetLabels",
          "rekognition:StartLabelDetection",
          "bedrock:InvokeModel",
          "bedrock:InvokeFlow",
          "bedrock:InvokeAgent"
        ]
        Resource = ["*"]
      }
    ]
  })
}

# -------------------------------
# IAM Roles for Lambdas
# -------------------------------
resource "aws_iam_role" "uploads_lambda_role" {
  name = "${var.project_name}-lambda-role-uploads"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role" "image_recog_lambda_role" {
  name = "${var.project_name}-lambda-role-image-recog"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "uploads_lambda_policy_attachment" {
  role       = aws_iam_role.uploads_lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_rekognition_logs.arn

}

resource "aws_iam_role_policy_attachment" "image_recog_lambda_policy_attachment" {
  role       = aws_iam_role.image_recog_lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_rekognition_logs.arn
}

# -------------------------------
# Archive Lambda Code
# -------------------------------
data "archive_file" "uploads_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/upload"
  output_path = "${path.module}/../lambda_upload.zip"
  depends_on  = [aws_iam_role.uploads_lambda_role]
}

data "archive_file" "image_recog_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/image_recog"
  output_path = "${path.module}/../lambda_image_recog.zip"
  depends_on  = [aws_iam_role.image_recog_lambda_role]
}

# -------------------------------
# Lambda Functions
# -------------------------------
resource "aws_lambda_function" "uploads" {
  function_name    = "${var.project_name}-uploads-handler"
  filename         = data.archive_file.uploads_lambda.output_path
  source_code_hash = data.archive_file.uploads_lambda.output_base64sha256
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.uploads_lambda_role.arn
  memory_size      = local.lambda_memory
  architectures    = ["x86_64"]

  environment {
    variables = local.lambda_env_vars
  }

  logging_config {
    log_format            = "JSON"
    application_log_level = "INFO"
    system_log_level      = "WARN"
  }
}

resource "aws_lambda_function" "image_recog" {
  function_name    = "${var.project_name}-image-recog-handler"
  filename         = data.archive_file.image_recog_lambda.output_path
  source_code_hash = data.archive_file.image_recog_lambda.output_base64sha256
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.image_recog_lambda_role.arn
  memory_size      = local.lambda_memory
  architectures    = ["x86_64"]

  environment {
    variables = local.lambda_env_vars
  }

  logging_config {
    log_format            = "JSON"
    application_log_level = "INFO"
    system_log_level      = "WARN"
  }
}

# -------------------------------
# S3 Bucket Notification
# -------------------------------
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_recog.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.main.arn

}

resource "aws_s3_bucket_notification" "upload_trigger" {
  bucket = aws_s3_bucket.main.bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.image_recog.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = local.uploads_prefix
    filter_suffix       = ".jpg"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}


# -------------------------------
# Lambda Function URLs and CORS 
# -------------------------------

resource "aws_lambda_function_url" "uploads_url" {
  function_name      = aws_lambda_function.uploads.arn
  authorization_type = "NONE"

  cors {
    allow_origins = ["*"] # Or limit to your Vercel domain - LATER =- #TODO
    allow_methods = ["GET", "POST"]
    max_age       = 86400
  }
}

resource "aws_lambda_permission" "allow_public_invoke_uploads" {
  statement_id           = "AllowPublicInvoke"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.uploads.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

#upload s3: aws s3 cp bird1.jpg s3://11-serverless-image-recog-poem-bucket/uploads/bird.jpg
# delete s3: aws s3 rm s3://11-serverless-image-recog-poem-bucket/uploads/bird.jpg
