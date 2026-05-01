# ─────────────────────────────────────────────
# Lambda Package: EC2 Scheduler
# ─────────────────────────────────────────────

data "archive_file" "scheduler" {
  type        = "zip"
  source_file = "${path.module}/../src/lambda/scheduler.py"
  output_path = "${path.module}/../.build/scheduler.zip"
}

resource "aws_lambda_function" "ec2_scheduler" {
  function_name    = "${var.project_name}-ec2-scheduler-${var.environment}"
  role             = aws_iam_role.scheduler_lambda.arn
  handler          = "scheduler.lambda_handler"
  runtime          = var.lambda_runtime
  filename         = data.archive_file.scheduler.output_path
  source_code_hash = data.archive_file.scheduler.output_base64sha256
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
      DRY_RUN       = tostring(var.dry_run)
      ENVIRONMENT   = var.environment
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.scheduler_lambda,
    aws_cloudwatch_log_group.scheduler,
  ]

  tags = merge(var.tags, { Name = "${var.project_name}-ec2-scheduler" })
}

resource "aws_cloudwatch_log_group" "scheduler" {
  name              = "/aws/lambda/${var.project_name}-ec2-scheduler-${var.environment}"
  retention_in_days = 14
}

# ─────────────────────────────────────────────
# Lambda Package: Cost Anomaly Reporter
# ─────────────────────────────────────────────

data "archive_file" "cost_reporter" {
  type        = "zip"
  source_file = "${path.module}/../src/lambda/cost_anomaly_reporter.py"
  output_path = "${path.module}/../.build/cost_anomaly_reporter.zip"
}

resource "aws_lambda_function" "cost_anomaly_reporter" {
  function_name    = "${var.project_name}-cost-reporter-${var.environment}"
  role             = aws_iam_role.cost_reporter_lambda.arn
  handler          = "cost_anomaly_reporter.lambda_handler"
  runtime          = var.lambda_runtime
  filename         = data.archive_file.cost_reporter.output_path
  source_code_hash = data.archive_file.cost_reporter.output_base64sha256
  timeout          = 30
  memory_size      = 128

  environment {
    variables = {
      ALERT_SNS_TOPIC_ARN = aws_sns_topic.alerts.arn
      COST_THRESHOLD_USD  = tostring(var.cost_anomaly_threshold)
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.cost_reporter_lambda,
    aws_cloudwatch_log_group.cost_reporter,
  ]

  tags = merge(var.tags, { Name = "${var.project_name}-cost-reporter" })
}

resource "aws_cloudwatch_log_group" "cost_reporter" {
  name              = "/aws/lambda/${var.project_name}-cost-reporter-${var.environment}"
  retention_in_days = 14
}

# Allow Cost Anomaly Detection SNS to invoke cost reporter Lambda
resource "aws_lambda_permission" "allow_anomaly_sns" {
  statement_id  = "AllowAnomalySNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_anomaly_reporter.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.cost_anomaly_raw.arn
}
