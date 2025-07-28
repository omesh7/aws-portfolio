terraform {
  required_providers {
    klayers = {
      version = "~> 1.0.0"
      source  = "ldcorentin/klayer"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Create Lambda deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/../lambda_function.zip"
}

# Lambda function
resource "aws_lambda_function" "controller" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  layers = [
    "arn:aws:lambda:ap-south-1:982534384941:layer:pygithub_layer:2",
    "arn:aws:lambda:ap-south-1:770693421928:layer:Klayers-p311-requests:18"
  ]
  environment {
    variables = {
      GITHUB_TOKEN     = var.github_token
      GITHUB_USERNAME  = var.github_username
      TFC_API_TOKEN    = var.tfc_api_token
      TFC_ORGANIZATION = var.tfc_organization
    }
  }
}

# Lambda Function URL
resource "aws_lambda_function_url" "controller_url" {
  function_name      = aws_lambda_function.controller.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["date", "keep-alive"]
    max_age           = 86400
  }
}
