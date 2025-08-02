output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.game_2048.repository_url
}

output "lambda_function_url" {
  description = "Lambda Function URL"
  value       = aws_lambda_function_url.game_api_url.function_url
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "s3_bucket_name" {
  description = "S3 bucket name for frontend"
  value       = aws_s3_bucket.frontend.bucket
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.game_api.function_name
}

output "codepipeline_name" {
  description = "CodePipeline name"
  value       = aws_codepipeline.pipeline.name
}