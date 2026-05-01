# ─────────────────────────────────────────────
# IAM Role: EC2 Scheduler Lambda
# ─────────────────────────────────────────────

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "scheduler_lambda" {
  name               = "${var.project_name}-scheduler-lambda-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "scheduler_lambda" {
  # EC2: describe and start/stop only — no terminate, no create
  statement {
    sid    = "EC2DescribeAndSchedule"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:StartInstances",
      "ec2:StopInstances",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/AutoSchedule"
      values   = ["*"]
    }
  }

  # Allow describe without tag condition (needed for paginator)
  statement {
    sid    = "EC2Describe"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
    ]
    resources = ["*"]
  }

  # SNS: publish alerts
  statement {
    sid       = "SNSPublish"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.alerts.arn]
  }

  # CloudWatch Logs
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "scheduler_lambda" {
  name   = "${var.project_name}-scheduler-policy-${var.environment}"
  policy = data.aws_iam_policy_document.scheduler_lambda.json
}

resource "aws_iam_role_policy_attachment" "scheduler_lambda" {
  role       = aws_iam_role.scheduler_lambda.name
  policy_arn = aws_iam_policy.scheduler_lambda.arn
}

# ─────────────────────────────────────────────
# IAM Role: Cost Anomaly Reporter Lambda
# ─────────────────────────────────────────────

resource "aws_iam_role" "cost_reporter_lambda" {
  name               = "${var.project_name}-cost-reporter-lambda-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "cost_reporter_lambda" {
  statement {
    sid       = "CostExplorerRead"
    effect    = "Allow"
    actions   = ["ce:GetCostAndUsage", "ce:GetAnomalies"]
    resources = ["*"]
  }

  statement {
    sid       = "SNSPublish"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.alerts.arn]
  }

  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "cost_reporter_lambda" {
  name   = "${var.project_name}-cost-reporter-policy-${var.environment}"
  policy = data.aws_iam_policy_document.cost_reporter_lambda.json
}

resource "aws_iam_role_policy_attachment" "cost_reporter_lambda" {
  role       = aws_iam_role.cost_reporter_lambda.name
  policy_arn = aws_iam_policy.cost_reporter_lambda.arn
}
