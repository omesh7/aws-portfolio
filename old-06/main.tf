

provider "aws" {
  region = "ap-south-1"
}
#-------------------------------------S3 BUCKET--------------------------------------------

# ######################
# # 1. SOURCE BUCKET
# ######################

resource "aws_s3_bucket" "source_bucket" {
  bucket        = "05-smart-resizer-source-images-aws-portfolio"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "source_versioning" {
  bucket = aws_s3_bucket.source_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
#---------------------------------------------------------------------------------

# ######################
# # 1. RESIZED BUCKET
# ######################

resource "aws_s3_bucket" "resized_bucket" {
  bucket        = "05-smart-resizer-output-images-aws-portfolio"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "resized_bucket_versioning" {
  bucket = aws_s3_bucket.resized_bucket.id
  versioning_configuration {
    status = "Enabled"
  }

}
#---------------------------------------------------------------------------------

# Public Read Access for Resized Images
resource "aws_s3_bucket_policy" "resized_public_read_policy" {
  bucket = aws_s3_bucket.resized_bucket.id

  depends_on = [
    aws_s3_bucket_public_access_block.allow_public_resized
  ]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "${aws_s3_bucket.resized_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket_website_configuration" "resized_website" {
  bucket = aws_s3_bucket.resized_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "allow_public_resized" {
  bucket = aws_s3_bucket.resized_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

#-----------------------------------------LAMBDA----------------------------------------

#######################
# IAM for Lambda - GENERATE JSON DOCUMENT
#######################

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}


#######################
# ROLE & POlicy for Lambda
#######################
resource "aws_iam_role" "lambda_exec_role" {
  name               = "lambda_basic_exec_role_aws_portfolio"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "s3_access_policy" {
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:PutObject"],
        Resource = "${aws_s3_bucket.source_bucket.arn}/*"
      },
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject", "s3:PutObject"],
        Resource = "${aws_s3_bucket.resized_bucket.arn}/*"
      }
    ]
  })
}


#######################
# Package - Deploy
#######################

data "archive_file" "resizer_lambda_zip" {
  type        = "zip"
  source_dir  = "./lambda/resizer"
  output_path = "./lambda/resizer.zip"
  excludes = [
    ".git",
    ".gitignore",
    "README.md"
  ]
}

resource "aws_lambda_function" "resizer_lambda" {
  function_name = "05_image_resizer_lambda"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  filename         = data.archive_file.resizer_lambda_zip.output_path
  source_code_hash = data.archive_file.resizer_lambda_zip.output_base64sha256
}


#######################
# API Gateway (HTTP API)
#######################
resource "aws_apigatewayv2_api" "http_api" {
  name          = "image-resizer-api-05-aws-portfolio"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "resizer_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.resizer_lambda.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

#######################
# ROUTES
#######################
resource "aws_apigatewayv2_route" "upload_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /upload"
  target    = "integrations/${aws_apigatewayv2_integration.resizer_integration.id}"
}

resource "aws_apigatewayv2_route" "resize_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /resize/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.resizer_integration.id}"
}

#######################
# Permission and Gateway
#######################
resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.resizer_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

output "resizer_api_endpoint" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}
