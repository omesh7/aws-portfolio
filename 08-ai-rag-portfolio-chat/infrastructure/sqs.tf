

resource "aws_sqs_queue" "project_queue" {
  name                      = "${var.project_name}-queue"
  delay_seconds             = 90
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 15
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.project_queue_deadletter.arn
    maxReceiveCount     = 5
  })
  visibility_timeout_seconds = 920 # ≥ lambda timeout

}



resource "aws_sqs_queue" "project_queue_deadletter" {
  name = "${var.project_name}-deadletter-queue"
}

resource "aws_sqs_queue_redrive_allow_policy" "terraform_queue_redrive_allow_policy" {
  queue_url = aws_sqs_queue.project_queue_deadletter.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.project_queue.arn]
  })

}


resource "aws_lambda_event_source_mapping" "sqs_lambda_event" {
  event_source_arn = aws_sqs_queue.project_queue.arn
  function_name    = aws_lambda_function.lambda_function.arn
  batch_size       = 1
  enabled          = true
  scaling_config {
    maximum_concurrency = 10
  }

}
