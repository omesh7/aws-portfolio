output "s3_bucket" {
  value = aws_s3_bucket.kb.id
}

output "aurora_cluster_arn" {
  value = module.aurora.cluster_arn

}

output "lambda_chat_url" {
  value = aws_lambda_function_url.chat_url.function_url
}
output "lambda_ingest_function_name" {
  value = aws_lambda_function.ingest.function_name
}
