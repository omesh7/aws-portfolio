output "s3_bucket_name" {
  value = module.s3.bucket_name
}

output "lambda_function_url" {
  value = module.lambda.lambda_url
}
