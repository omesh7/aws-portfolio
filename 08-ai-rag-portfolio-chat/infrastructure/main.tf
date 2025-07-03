terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
}

provider "aws" {
  region = "ap-south-1"
}

resource "aws_s3_bucket" "readme_bucket" {
  bucket = var.s3_bucket



  force_destroy = true
  region        = "ap-south-1"

  tags = {
    Name        = "README RAG Bucket"
    Environment = "Development"
    project-no  = "8"
  }
  tags_all = {
    Name        = "README RAG Bucket"
    Environment = "Development"
  }


}

# IAM Role for Lambda execution
resource "aws_iam_role" "lambda_role" {
  name = "ai_rag_08_lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  description           = "IAM role for Lambda function to access S3 and CloudWatch Logs"
  force_detach_policies = true
  max_session_duration  = 3600
  path                  = "/"
  permissions_boundary  = null
  tags = {
    Name        = "ai_rag_08_lambda_role"
    Environment = "Development"
    project-no  = "8"
  }
  depends_on = [aws_s3_bucket.readme_bucket]
}

resource "aws_iam_policy" "lambda_policy" {
  name = "ai_rag_08_lambda_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject"],
        Resource = "arn:aws:s3:::${var.s3_bucket}/*"
      }
    ]
  })
  description = "IAM policy for Lambda function to access S3 and CloudWatch Logs"
  tags = {
    Name        = "ai_rag_08_lambda_policy"
    Environment = "Development"
    project-no  = "8"
  }

  depends_on = [aws_s3_bucket.readme_bucket]
}

# Upload the README.md file to the bucket
resource "aws_s3_object" "readme" {
  bucket       = aws_s3_bucket.readme_bucket.id
  key          = "${var.s3_bucket_prefix}/README.md"
  source       = "${path.module}/../../README.md"
  etag         = filemd5("${path.module}/../../README.md")
  content_type = "text/markdown"
  acl          = "private"
  tags = {
    Name        = "README.md"
    Environment = "Development"
    project-no  = "8"
  }
  depends_on = [aws_s3_bucket.readme_bucket]

}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
  depends_on = [aws_iam_role.lambda_role, aws_iam_policy.lambda_policy]

}

# Package code into ZIP
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/../lambda_08_project.zip"
  depends_on  = [aws_iam_role.lambda_role, aws_iam_role_policy_attachment.lambda_attach]
}

# Lambda function
resource "aws_lambda_function" "ai_rag_08_handler" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "08-ai-portfolio-rag-chat"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 320
  package_type     = "Zip"
  skip_destroy     = false
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.readme_bucket.bucket
      S3_KEY    = aws_s3_object.readme.key
    }
  }
  tags = {
    Name        = "ai_rag_08_handler"
    Environment = "Development"
    project-no  = "8"
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_attach, aws_s3_object.readme, data.archive_file.lambda_zip]
}

# Create the Function URL
resource "aws_lambda_function_url" "ai_rag_08_url" {
  function_name      = aws_lambda_function.ai_rag_08_handler.function_name
  authorization_type = "NONE"
  cors {
    allow_credentials = false
    allow_headers     = ["*"]
    allow_methods     = ["GET", "POST"]
    allow_origins     = ["*"]
    expose_headers    = []
    max_age           = 3600
  }
  depends_on = [aws_lambda_function.ai_rag_08_handler]
}

