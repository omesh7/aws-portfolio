# -------------------------------
# IAM Policy for Lambda
# -------------------------------
resource "aws_iam_policy" "lambda_s3_rekognition_logs" {
  name        = "${var.project_name}-lambda_s3_rekognition_logging"
  description = "Allows Lambda access to S3, Rekognition, and CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "rekognition:DetectText",
          "rekognition:DetectLabels",
          "rekognition:GetLabelDetection",
          "rekognition:RecognizeCelebrities",
          "rekognition:DetectCustomLabels",
          "rekognition:DetectModerationLabels",
          "rekognition:ListDatasetLabels",
          "rekognition:StartLabelDetection",
          "bedrock:InvokeModel",
          "bedrock:InvokeFlow",
          "bedrock:InvokeAgent",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = ["*"]
      }
    ]
  })
}

# -------------------------------
# IAM Roles for Lambdas
# -------------------------------
resource "aws_iam_role" "uploads_lambda_role" {
  name = "${var.project_name}-lambda-role-uploads"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role" "image_recog_lambda_role" {
  name = "${var.project_name}-lambda-role-image-recog"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role" "get_poem_lambda_role" {
  name = "${var.project_name}-lambda-role-get-poem"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "uploads_lambda_policy_attachment" {
  role       = aws_iam_role.uploads_lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_rekognition_logs.arn
}

resource "aws_iam_role_policy_attachment" "image_recog_lambda_policy_attachment" {
  role       = aws_iam_role.image_recog_lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_rekognition_logs.arn
}

resource "aws_iam_role_policy_attachment" "get_poem_lambda_policy_attachment" {
  role       = aws_iam_role.get_poem_lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_rekognition_logs.arn
}