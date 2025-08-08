
module "s3" {
  source = "./modules/s3"
  sku    = var.project_suffix
  tags   = var.tags
}

module "iam" {
  source     = "./modules/iam"
  bucket_arn = module.s3.bucket_arn
  tags       = var.tags
}


# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/ai-rag-processor-${var.project_suffix}"
  retention_in_days = 14
  tags              = var.tags
}

module "lambda" {
  source             = "./modules/lambda"
  role_arn           = module.iam.role_arn
  bucket_name        = module.s3.bucket_name
  embed_model        = var.embed_model
  image_uri          = var.image_uri
  tags               = var.tags
  project_suffix     = var.project_suffix
  log_group_name     = aws_cloudwatch_log_group.lambda_logs.name
  vector_bucket_name = var.vector_bucket_name
}

resource "aws_s3_bucket_notification" "kb_notify" {
  bucket = module.s3.bucket_id
  lambda_function {
    lambda_function_arn = module.lambda.lambda_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "docs/"
  }
  depends_on = [module.lambda]
}


# --- Upload test file to trigger Lambda ---
resource "null_resource" "always_run" {
  triggers = {
    timestamp = timestamp()
  }
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "lambda-errors-${var.project_suffix}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Lambda function errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = module.lambda.function_name
  }
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "lambda-duration-${var.project_suffix}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = "240000"
  alarm_description   = "Lambda function duration high"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = module.lambda.function_name
  }
  tags = var.tags
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "ai-rag-alerts-${var.project_suffix}"
  tags = var.tags
}

resource "aws_s3_object" "test_md_file" {
  bucket       = module.s3.bucket_name
  key          = "docs/test.txt"
  source       = "${path.module}/test-docs/test.txt"
  content_type = "text/plain"

  depends_on = [
    aws_s3_bucket_notification.kb_notify,
    null_resource.always_run
  ]
}

