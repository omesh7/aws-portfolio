output "files_endpoint" {
  value = "${aws_apigatewayv2_api.api.api_endpoint}/files"
}

output "functions_endpoint" {
  value = "${aws_apigatewayv2_api.api.api_endpoint}/func"
}

output "lambda_function_name" {
  value       = aws_lambda_function.list_s3.function_name
  description = "Name of the Lambda function that lists files in the S3 bucket"
}
