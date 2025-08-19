


resource "aws_iam_role" "lambda_exec" {
  name = "kinesis-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "lambda-kinesis-dynamodb-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["dynamodb:PutItem"],
        Resource = aws_dynamodb_table.anomaly_data.arn
      },
      {
        Effect   = "Allow",
        Action   = ["logs:*"],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:ListStreams"
        ],
        Resource = aws_kinesis_stream.anomaly_stream.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.project_name}-kinesis-consumer"
  retention_in_days = 7
}

resource "aws_lambda_function" "kinesis_consumer" {
  function_name    = "${var.project_name}-kinesis-consumer"
  role             = aws_iam_role.lambda_exec.arn
  source_code_hash = local.lambda_kinesis_source_hash
  filename         = local.lambda_kinesis_filename
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  timeout          = 60
  
  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.anomaly_data.name
    }
  }
  
  lifecycle {
    create_before_destroy = true
  }
  
  depends_on = [aws_cloudwatch_log_group.lambda_logs]
}



resource "aws_lambda_event_source_mapping" "kinesis_trigger" {
  event_source_arn  = aws_kinesis_stream.anomaly_stream.arn
  function_name     = aws_lambda_function.kinesis_consumer.arn
  starting_position = "LATEST"
  batch_size        = 1
}



output "lambda_arn" {
  value = aws_lambda_function.kinesis_consumer.arn
}
