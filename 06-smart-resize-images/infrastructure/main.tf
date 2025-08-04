

resource "aws_s3_bucket" "resized_bucket" {
  bucket        = var.project_name
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket                  = aws_s3_bucket.resized_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.resized_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "PublicReadGetObject",
      Effect    = "Allow",
      Principal = "*",
      Action    = "s3:GetObject",
      Resource  = "${aws_s3_bucket.resized_bucket.arn}/*"
    }]
  })
  depends_on = [aws_s3_bucket_public_access_block.block]
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda-${var.project_name}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/../lambda_05_project.zip"
}

resource "aws_lambda_function" "resize_upload" {
  function_name    = "${var.project_name}-resize-upload-function"
  description      = "Lambda function to resize uploaded images"
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)
  role             = aws_iam_role.lambda_exec.arn

  # layers = [
  #   "arn:aws:lambda:ap-south-1:982534384941:layer:sharp:1"
  # ]
  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.resized_bucket.bucket
      REGION      = var.aws_region
    }
  }
  depends_on = [aws_iam_role_policy_attachment.s3_full_access]
}

resource "aws_apigatewayv2_api" "api" {
  name          = "resize-upload-api-aws-portfolio"
  description   = "API for resizing uploaded images"
  protocol_type = "HTTP"
  cors_configuration {
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_origins = ["*"]
    allow_headers = ["Content-Type"]
  }
  tags = {
    Name        = "resize-upload-api"
    Environment = "Production"
  }
  depends_on = [aws_lambda_function.resize_upload]
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
  description = "Default stage for the resize upload API"
  depends_on  = [aws_apigatewayv2_api.api]
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.resize_upload.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
  depends_on    = [aws_apigatewayv2_stage.default]
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.resize_upload.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
  timeout_milliseconds   = 29000
  depends_on             = [aws_lambda_permission.apigw]
}

resource "aws_apigatewayv2_route" "resize_route" {
  api_id     = aws_apigatewayv2_api.api.id
  route_key  = "POST /resize"
  target     = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
  depends_on = [aws_apigatewayv2_integration.lambda_integration]
}


resource "aws_apigatewayv2_route" "hello_route" {
  api_id     = aws_apigatewayv2_api.api.id
  route_key  = "GET /hello"
  target     = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
  depends_on = [aws_apigatewayv2_integration.lambda_integration]
}

output "resize_url" {
  value       = "${aws_apigatewayv2_api.api.api_endpoint}/resize"
  description = "URL to resize images"
}

