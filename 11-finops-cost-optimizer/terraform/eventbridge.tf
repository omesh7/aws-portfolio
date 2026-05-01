# ─────────────────────────────────────────────
# EventBridge Rule: EC2 Scheduler (runs every 5 min)
# ─────────────────────────────────────────────

resource "aws_cloudwatch_event_rule" "scheduler" {
  name                = "${var.project_name}-ec2-scheduler-${var.environment}"
  description         = "Triggers EC2 start/stop Lambda on schedule to optimize costs"
  schedule_expression = var.scheduler_cron
  state               = "ENABLED"
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "scheduler" {
  rule      = aws_cloudwatch_event_rule.scheduler.name
  target_id = "EC2SchedulerLambda"
  arn       = aws_lambda_function.ec2_scheduler.arn
}

resource "aws_lambda_permission" "allow_eventbridge_scheduler" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scheduler.arn
}
