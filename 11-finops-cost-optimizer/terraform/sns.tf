# ─────────────────────────────────────────────
# SNS: Human-readable alerts (email)
# ─────────────────────────────────────────────

resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts-${var.environment}"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ─────────────────────────────────────────────
# SNS: Raw Cost Anomaly Detection target
# (AWS Cost Anomaly Detection → this SNS → Lambda enrichment → alerts SNS)
# ─────────────────────────────────────────────

resource "aws_sns_topic" "cost_anomaly_raw" {
  name = "${var.project_name}-cost-anomaly-raw-${var.environment}"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "cost_anomaly_to_lambda" {
  topic_arn = aws_sns_topic.cost_anomaly_raw.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.cost_anomaly_reporter.arn
}

# Allow AWS Cost Anomaly Detection service to publish to raw SNS topic
resource "aws_sns_topic_policy" "cost_anomaly_raw" {
  arn = aws_sns_topic.cost_anomaly_raw.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCostAnomalyDetection"
        Effect = "Allow"
        Principal = {
          Service = "costalerts.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.cost_anomaly_raw.arn
      }
    ]
  })
}

# ─────────────────────────────────────────────
# AWS Cost Anomaly Detection Monitor + Subscription
# ─────────────────────────────────────────────

resource "aws_ce_anomaly_monitor" "account" {
  name              = "${var.project_name}-monitor-${var.environment}"
  monitor_type      = var.cost_anomaly_monitor_type

  # For DIMENSIONAL monitor, tracks the whole account
  dynamic "monitor_specification" {
    for_each = var.cost_anomaly_monitor_type == "CUSTOM" ? [1] : []
    content {
      and {
        cost_categories {
          key    = "Environment"
          values = [var.environment]
        }
      }
    }
  }

  tags = var.tags
}

resource "aws_ce_anomaly_subscription" "alert" {
  name      = "${var.project_name}-subscription-${var.environment}"
  frequency = "IMMEDIATE"

  monitor_arn_list = [aws_ce_anomaly_monitor.account.arn]

  subscriber {
    address = aws_sns_topic.cost_anomaly_raw.arn
    type    = "SNS"
  }

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      values        = [tostring(var.cost_anomaly_threshold)]
      match_options = ["GREATER_THAN_OR_EQUAL"]
    }
  }

  tags = var.tags
}
