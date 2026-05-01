output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "kinesis_stream_name" {
  value = aws_kinesis_stream.anomaly_stream.name
}

output "lambda_function_name" {
  value = aws_lambda_function.kinesis_consumer.function_name
}

