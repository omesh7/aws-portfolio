
# -------------------------------
# Outputs
# -------------------------------
output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.main.bucket
}

output "lambda_upload_url" {
  description = "URL for the uploads Lambda function"
  value       = aws_lambda_function_url.uploads_url.function_url
}

output "uploads_lambda_name" {
  description = "Name of the uploads Lambda function"
  value       = aws_lambda_function.uploads.function_name
}

output "image_recog_lambda_name" {
  description = "Name of the image recognition Lambda function"
  value       = aws_lambda_function.image_recog.function_name
}

output "get_poem_url" {
  description = "Lambda function URL for getting poem results"
  value       = aws_lambda_function_url.get_poem_url.function_url
}