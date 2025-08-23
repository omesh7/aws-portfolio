# -------------------------------
# Archive Lambda Code
# -------------------------------
data "archive_file" "uploads_lambda" {
  count       = local.use_local_archive ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/../lambda/upload"
  output_path = "${path.module}/../lambda_upload.zip"
  depends_on  = [aws_iam_role.uploads_lambda_role]
}

data "archive_file" "image_recog_lambda" {
  count       = local.use_local_archive ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/../lambda/image_recog"
  output_path = "${path.module}/../lambda_image_recog.zip"
  depends_on  = [aws_iam_role.image_recog_lambda_role]
}

data "archive_file" "get_poem_lambda" {
  count       = local.use_local_archive ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/../lambda/get_poem"
  output_path = "${path.module}/../lambda_get_poem.zip"
  depends_on  = [aws_iam_role.get_poem_lambda_role]
}

# -------------------------------
# CloudWatch Log Groups
# -------------------------------
resource "aws_cloudwatch_log_group" "uploads_lambda_logs" {
  name              = "/aws/lambda/${var.project_name}-uploads-handler"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "image_recog_lambda_logs" {
  name              = "/aws/lambda/${var.project_name}-image-recog-handler"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "get_poem_lambda_logs" {
  name              = "/aws/lambda/${var.project_name}-get-poem-handler"
  retention_in_days = 7
}

# -------------------------------
# Lambda Functions
# -------------------------------
resource "aws_lambda_function" "uploads" {
  function_name    = "${var.project_name}-uploads-handler"
  filename         = local.lambda_uploads_filename
  source_code_hash = local.lambda_uploads_source_hash
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.uploads_lambda_role.arn
  memory_size      = local.lambda_memory
  architectures    = ["x86_64"]
  timeout          = 30

  environment {
    variables = local.lambda_env_vars
  }

  logging_config {
    log_format            = "JSON"
    application_log_level = "INFO"
    system_log_level      = "WARN"
  }

  depends_on = [aws_cloudwatch_log_group.uploads_lambda_logs]
}

resource "aws_lambda_function" "image_recog" {
  function_name    = "${var.project_name}-image-recog-handler"
  filename         = local.lambda_image_recog_filename
  source_code_hash = local.lambda_image_recog_source_hash
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.image_recog_lambda_role.arn
  memory_size      = 256
  architectures    = ["x86_64"]
  timeout          = 60

  environment {
    variables = local.lambda_env_vars
  }

  logging_config {
    log_format            = "JSON"
    application_log_level = "INFO"
    system_log_level      = "WARN"
  }

  depends_on = [aws_cloudwatch_log_group.image_recog_lambda_logs]
}

resource "aws_lambda_function" "get_poem" {
  function_name    = "${var.project_name}-get-poem-handler"
  filename         = local.lambda_get_poem_filename
  source_code_hash = local.lambda_get_poem_source_hash
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.get_poem_lambda_role.arn
  memory_size      = local.lambda_memory
  architectures    = ["x86_64"]
  timeout          = 30

  environment {
    variables = local.lambda_env_vars
  }

  logging_config {
    log_format            = "JSON"
    application_log_level = "INFO"
    system_log_level      = "WARN"
  }

  depends_on = [aws_cloudwatch_log_group.get_poem_lambda_logs]
}

# -------------------------------
# Lambda Permissions
# -------------------------------
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_recog.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.main.arn
}

resource "aws_lambda_permission" "allow_public_invoke_uploads" {
  statement_id           = "AllowPublicInvoke"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.uploads.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_permission" "allow_public_invoke_get_poem" {
  statement_id           = "AllowPublicInvoke"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.get_poem.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

# -------------------------------
# Get Poem Lambda Function URL
# -------------------------------
resource "aws_lambda_function_url" "get_poem_url" {
  function_name      = aws_lambda_function.get_poem.arn
  authorization_type = "NONE"

  cors {
    allow_origins     = ["https://${var.subdomain}.${var.cloudflare_site}"]
    allow_methods     = ["GET", "POST"]
    allow_headers     = ["*"]
    expose_headers    = ["date", "keep-alive"]
    max_age           = 86400
    allow_credentials = false
  }
}

# -------------------------------
# Lambda Function URLs and CORS 
# -------------------------------
resource "aws_lambda_function_url" "uploads_url" {
  function_name      = aws_lambda_function.uploads.arn
  authorization_type = "NONE"

  cors {
    allow_origins     = ["https://${var.subdomain}.${var.cloudflare_site}"]
    allow_methods     = ["GET", "POST"]
    allow_headers     = ["*"]
    expose_headers    = ["date", "keep-alive"]
    max_age           = 86400
    allow_credentials = false
  }
}
