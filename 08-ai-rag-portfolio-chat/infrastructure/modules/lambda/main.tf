resource "aws_lambda_function" "ingest" {
  function_name = "rag-ingest-${var.project_suffix}"
  role          = var.role_arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  timeout       = 900
  filename      = var.function_zip
  layers        = ["arn:aws:lambda:ap-south-1:982534384941:layer:lambda_langchain_layer:1"]
  environment {
    variables = {
      BUCKET_NAME = var.bucket_name
      EMBED_MODEL = var.embed_model
    }
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = var.tags
}

resource "aws_lambda_function_url" "url" {
  function_name      = aws_lambda_function.ingest.function_name
  authorization_type = "NONE"
  cors {
    allow_origins = ["*"]
    allow_methods = ["POST"]
  }
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingest.arn
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.bucket_name}"
}

output "lambda_arn" {
  value = aws_lambda_function.ingest.arn
}

output "lambda_url" {
  value = aws_lambda_function_url.url.function_url
}
