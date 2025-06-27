provider "aws" {
  region = "ap-south-1"
}

# 1. IAM Role & Policies
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-s3-list-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
  tags = { Name = "lambda-s3-list-role", Environment = "dev" }
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "s3_readonly" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_readonly" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess"
}


# 2. Package Lambda
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda/lambda.zip"
}

# 3. Lambda Function
resource "aws_lambda_function" "list_s3" {
  function_name    = "list-s3-files-esm"
  runtime          = "nodejs18.x"
  handler          = "index.handler"
  role             = aws_iam_role.lambda_exec_role.arn
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)

  environment {
    variables = {
      AWS_NODEJS_CONNECTION_REUSE_ENABLED = "1"
      BUCKET_NAME                         = var.bucket_name
    }
  }

  tags = { Name = "lambda-list-s3-files", Environment = "dev" }
  depends_on = [
    aws_iam_role_policy_attachment.s3_readonly,
    aws_iam_role_policy_attachment.lambda_readonly
  ]

}

# 4. HTTP API Gateway
resource "aws_apigatewayv2_api" "api" {
  name          = "list-s3-files-api"
  protocol_type = "HTTP"
  tags          = { Name = "lambda-api", Environment = "dev" }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
  tags        = { Name = "lambda-stage", Environment = "dev" }
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list_s3.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
  depends_on    = [aws_lambda_function.list_s3]
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.list_s3.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
  depends_on             = [aws_lambda_permission.apigw]
}

resource "aws_apigatewayv2_route" "files_route" {
  api_id     = aws_apigatewayv2_api.api.id
  route_key  = "GET /files"
  target     = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
  depends_on = [aws_apigatewayv2_integration.lambda_integration]
}

resource "aws_apigatewayv2_route" "func_route" {
  api_id     = aws_apigatewayv2_api.api.id
  route_key  = "GET /func"
  target     = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
  depends_on = [aws_apigatewayv2_integration.lambda_integration]
}

# 5. Variable Declaration
variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket to list files from"
}

