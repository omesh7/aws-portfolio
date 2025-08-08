resource "aws_lambda_function" "ingest" {
  function_name = "${var.project_suffix}-function"
  role          = var.role_arn
  package_type  = "Image"
  image_uri     = var.image_uri
  timeout       = 900
  memory_size   = 1024

  environment {
    variables = {
      SRC_BUCKET          = var.bucket_name
      EMBED_MODEL         = var.embed_model
      VECTOR_BUCKET_NAME  = var.vector_bucket_name
    }
  }

  depends_on = [var.log_group_name]
  tags       = var.tags
}

resource "aws_lambda_function_url" "url" {
  function_name      = aws_lambda_function.ingest.function_name
  authorization_type = "NONE"
  cors {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST"]
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

output "function_name" {
  value = aws_lambda_function.ingest.function_name
}
