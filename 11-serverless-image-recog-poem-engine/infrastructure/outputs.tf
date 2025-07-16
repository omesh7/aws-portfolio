
output "aws_lambda_upload_url" {
  value = aws_lambda_function_url.uploads_url.function_url
}
