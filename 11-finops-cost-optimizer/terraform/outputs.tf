output "scheduler_lambda_arn" {
  description = "ARN of the EC2 scheduler Lambda function"
  value       = aws_lambda_function.ec2_scheduler.arn
}

output "scheduler_lambda_name" {
  description = "Name of the EC2 scheduler Lambda function"
  value       = aws_lambda_function.ec2_scheduler.function_name
}

output "cost_reporter_lambda_arn" {
  description = "ARN of the cost anomaly reporter Lambda"
  value       = aws_lambda_function.cost_anomaly_reporter.arn
}

output "alerts_sns_topic_arn" {
  description = "SNS topic ARN for human-readable alerts"
  value       = aws_sns_topic.alerts.arn
}

output "cost_anomaly_raw_sns_arn" {
  description = "SNS topic ARN that receives raw Cost Anomaly Detection events"
  value       = aws_sns_topic.cost_anomaly_raw.arn
}

output "cost_anomaly_monitor_arn" {
  description = "ARN of the AWS Cost Anomaly Detection monitor"
  value       = aws_ce_anomaly_monitor.account.arn
}

output "eventbridge_rule_arn" {
  description = "EventBridge rule ARN for the EC2 scheduler"
  value       = aws_cloudwatch_event_rule.scheduler.arn
}

output "scheduler_log_group" {
  description = "CloudWatch Log Group for the EC2 scheduler Lambda"
  value       = aws_cloudwatch_log_group.scheduler.name
}

output "cost_reporter_log_group" {
  description = "CloudWatch Log Group for the cost reporter Lambda"
  value       = aws_cloudwatch_log_group.cost_reporter.name
}
