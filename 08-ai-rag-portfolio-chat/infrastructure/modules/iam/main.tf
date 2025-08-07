resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_iam_role" "lambda_role" {
  name = "rag-lambda-role-${random_id.suffix.hex}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_policy" "lambda_policy" {
  name = "rag-lambda-policy-${random_id.suffix.hex}"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject", "s3:PutObject"],
        Resource = "${var.bucket_arn}/*"
      },
      {
        Effect   = "Allow",
        Action   = ["s3:ListBucket"],
        Resource = var.bucket_arn
      },
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["bedrock:InvokeModel"],
        Resource = "arn:aws:bedrock:*:*:foundation-model/amazon.titan-*"
      },
      {
        Effect   = "Allow",
        Action   = ["cloudwatch:PutMetricData"],
        Resource = "*"
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

output "role_arn" {
  value = aws_iam_role.lambda_role.arn
}
