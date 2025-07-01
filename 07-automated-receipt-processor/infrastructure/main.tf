provider "aws" {
  region = "ap-south-1" # or your region
}

resource "aws_sns_topic" "reciept_notifications" {

  application_success_feedback_sample_rate = 0

  content_based_deduplication = false

  display_name = "ReceiptNotifications-07-aws-portfolio"

  fifo_topic = false

  firehose_success_feedback_sample_rate = 0

  http_success_feedback_sample_rate = 0

  lambda_success_feedback_sample_rate = 0
  name                                = "ReceiptNotifications"
  policy = jsonencode({
    Id = "__default_policy_ID"
    Statement = [{
      Action = ["SNS:Publish", "SNS:RemovePermission", "SNS:SetTopicAttributes", "SNS:DeleteTopic", "SNS:ListSubscriptionsByTopic", "SNS:GetTopicAttributes", "SNS:AddPermission", "SNS:Subscribe"]
      Condition = {
        StringEquals = {
          "AWS:SourceAccount" = "982534384941"
        }
      }
      Effect = "Allow"
      Principal = {
        AWS = "*"
      }
      Resource = "arn:aws:sns:ap-south-1:982534384941:ReceiptNotifications"
      Sid      = "__default_statement_ID"
    }]
    Version = "2008-10-17"
  })
  region = "ap-south-1"

  tracing_config = "PassThrough"
  tags = {
    "project-no" = "7"
  }
}

# __generated__ by Terraform
resource "aws_lambda_function" "process_receipt" {
  architectures    = ["x86_64"]
  description      = "lambda fucntion to automate Reciepts Processing"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  function_name                  = "07-automated-receipt-processor"
  handler                        = "lambda_function.lambda_handler"
  memory_size                    = 128
  package_type                   = "Zip"
  region                         = "ap-south-1"
  reserved_concurrent_executions = -1
  role                           = "arn:aws:iam::982534384941:role/lambda-receipt-processor-role-07-aws-portfolio"
  runtime                        = "python3.11"
  skip_destroy                   = false
  tags = {
    "project-no" = "7"
  }

  timeout = 183
  environment {
    variables = {
      DYNAMODB_TABLE          = "Receipts"
      NOTIFICATION_LOG_BUCKET = "07-receipt-processor-aws-portfolio"
      SNS_TOPIC_ARN           = "arn:aws:sns:ap-south-1:982534384941:ReceiptNotifications"
    }
  }
  ephemeral_storage {
    size = 512
  }
  logging_config {
    application_log_level = null
    log_format            = "Text"
    log_group             = "/aws/lambda/07-automated-receipt-processor"
    system_log_level      = null
  }
  tracing_config {
    mode = "PassThrough"
  }
}

# __generated__ by Terraform
resource "aws_dynamodb_table" "receipts_table" {
  billing_mode                = "PAY_PER_REQUEST"
  deletion_protection_enabled = false
  hash_key                    = "receipt_id"
  name                        = "Receipts"
  range_key                   = "date"
  read_capacity               = 0
  region                      = "ap-south-1"
  stream_enabled              = false
  table_class                 = "STANDARD"
  tags = {
    "project-no" = "7"
  }
  tags_all = {
    "project-no" = "7"
  }
  write_capacity = 0
  attribute {
    name = "date"
    type = "S"
  }
  attribute {
    name = "receipt_id"
    type = "S"
  }
  ttl {
    attribute_name = null
    enabled        = false
  }
}

# __generated__ by Terraform from "07-receipt-processor-aws-portfolio"
resource "aws_s3_bucket" "uploads_bucket" {
  bucket              = "07-receipt-processor-aws-portfolio"
  bucket_prefix       = null
  force_destroy       = false
  object_lock_enabled = false
  region              = "ap-south-1"
  tags = {
    "project-no" = "7"
  }
  tags_all = {}
}

# __generated__ by Terraform from "lambda-receipt-processor-role-07-aws-portfolio"
resource "aws_iam_role" "lambda_exec" {
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
  description           = "Allows Lambda functions to call AWS services on your behalf."
  force_detach_policies = false
  max_session_duration  = 3600
  name                  = "lambda-receipt-processor-role-07-aws-portfolio"
  name_prefix           = null
  path                  = "/"
  permissions_boundary  = null
  tags = {
    "project-no" = "7"
  }
  tags_all = {
    "project-no" = "7"
  }
}


data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/../lambda_07_project.zip"
  depends_on  = [aws_iam_role.lambda_exec]

}
