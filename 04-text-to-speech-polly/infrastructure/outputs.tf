output "lambda_function_url" {
  description = "Lambda Function URL endpoint"
  value       = aws_lambda_function_url.polly_tts_url.function_url
}

output "s3_bucket_name" {
  description = "S3 bucket name for audio files"
  value       = aws_s3_bucket.polly_audio.bucket
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.polly_tts.function_name
}