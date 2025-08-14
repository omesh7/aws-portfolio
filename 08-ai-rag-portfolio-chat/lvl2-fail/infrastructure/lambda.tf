
resource "aws_lambda_function" "lambda_function" {
  function_name = "${var.project_name}-function"
  package_type  = "Image"
  role          = aws_iam_role.lambda_role.arn
  image_uri     = var.image_uri
  timeout       = 900
  memory_size   = 1024

  environment {
    variables = {
      BUCKET             = aws_s3_bucket.main_bucket.bucket
      EMBEDDING_MODEL_ID = var.embed_model
      MODEL_ID           = var.chat_model
      MEMORY_TABLE       = aws_dynamodb_table.memory_table.name
      DOCUMENT_TABLE     = aws_dynamodb_table.document_table.name
      QUEUE              = aws_sqs_queue.project_queue.url
    }
  }
  lifecycle {
    prevent_destroy = false
  }

}

resource "aws_lambda_function_url" "url" {
  function_name      = aws_lambda_function.lambda_function.function_name
  authorization_type = "NONE"
  cors {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST"]
  }
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "Allows3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.main_bucket.arn
}



output "lambda_arn" {
  value = aws_lambda_function.lambda_function.arn
}

output "lambda_url" {
  value = aws_lambda_function_url.url.function_url
}

output "function_name" {
  value = aws_lambda_function.lambda_function.function_name
}

resource "aws_cloudwatch_log_group" "lambda_log" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_function.function_name}"
  retention_in_days = 1
}
