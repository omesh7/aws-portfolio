output "function_url" {
  description = "Lambda Function URL"
  value       = aws_lambda_function_url.controller_url.function_url
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.controller.function_name
}