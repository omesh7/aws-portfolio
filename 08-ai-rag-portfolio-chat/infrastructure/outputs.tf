output "s3_bucket_name" {
  value = module.s3.bucket_name
}

output "lambda_function_url" {
  value = module.lambda.lambda_url
}

output "cloudwatch_log_group" {
  value = aws_cloudwatch_log_group.lambda_logs.name
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "lambda_function_name" {
  value = module.lambda.function_name
}
