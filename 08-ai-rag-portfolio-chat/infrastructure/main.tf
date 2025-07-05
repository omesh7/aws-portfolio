# ----------------------------------
# Terraform AWS RAG Infrastructure
# ----------------------------------

terraform {
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 6.0" }
    random = { source = "hashicorp/random", version = "~> 3.0" }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# -------------------------------
# Locals
# -------------------------------
locals {
  sku         = "eight-${random_id.rag_suffix.hex}"
  bucket_name = "rag-kb-${local.sku}"
  db_username = var.db_user
  db_name     = var.db_name
  db_schema   = var.db_schema
  db_table    = var.table_name
  embed_model = var.embed_model
  chat_model  = var.chat_model

}

# Unique suffix for resource names
resource "random_id" "rag_suffix" {
  byte_length = 4
}

# -------------------------------
# 1. S3 Knowledge Base Bucket
# -------------------------------
resource "aws_s3_bucket" "kb" {
  bucket        = local.bucket_name
  force_destroy = true
  tags          = { Name = "RAG KB Bucket", "project-no" = "8" }
}

# Trigger Lambda on new file upload to docs/
resource "aws_s3_bucket_notification" "kb_notify" {
  bucket = aws_s3_bucket.kb.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.ingest.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "docs/"
  }
  depends_on = [aws_lambda_permission.allow_s3]
}

# -------------------------------
# 2. Aurora Serverless Cluster
# -------------------------------
module "aurora" {
  source         = "terraform-aws-modules/rds-aurora/aws"
  version        = "9.15.0"
  engine         = "aurora-postgresql"
  engine_mode    = "serverless"
  engine_version = "17.4"
  vpc_id         = var.vpc_id
  subnets        = var.subnet_ids
  name           = "rag-aurora-${local.sku}-08" # ✅ Valid name


  database_name          = local.db_name
  db_subnet_group_name   = "rag-aurora-subnet-group-${local.sku}"

  create_security_group = true
  tags = {
    Name         = "RAG Aurora Cluster"
    Environment  = "Production"
    Project      = "RAG Portfolio Chat"
    "project-no" = "8"
  }
}

# -------------------------------
# 3. Secrets Manager for DB Creds
# -------------------------------
resource "aws_secretsmanager_secret" "db" {
  name = "rag-db-secret-${local.sku}"
}

resource "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = local.db_username
    password = var.db_password
  })
}

# -------------------------------
# 4. IAM Role and Policy for Lambda
# -------------------------------
resource "aws_iam_role" "lambda_role" {
  name = "rag-lambda-role-${local.sku}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
  tags = {
    Name         = "RAG Lambda Role"
    Environment  = "Production"
    Project      = "RAG Portfolio Chat"
    "project-no" = "8"
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name = "rag-lambda-policy-${local.sku}"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect = "Allow", Action = ["s3:GetObject"], Resource = "${aws_s3_bucket.kb.arn}/*" },
      { Effect = "Allow", Action = ["rds-data:ExecuteStatement"], Resource = module.aurora.cluster_arn
      },
      { Effect = "Allow", Action = ["secretsmanager:GetSecretValue"], Resource = aws_secretsmanager_secret.db.arn },
      { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = "*" }
    ]
  })
  tags = {
    Name         = "RAG Lambda Policy"
    Environment  = "Production"
    Project      = "RAG Portfolio Chat"
    "project-no" = "8"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn

}

# -------------------------------
# 5. Lambda Function for Ingest
# -------------------------------

# Zip Lambda code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/../lambda_08_project.zip"
}

# Create Lambda function
resource "aws_lambda_function" "ingest" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "rag_ingest_${local.sku}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 900

  environment {
    variables = {
      EMBED_MODEL    = local.embed_model
      DB_SECRET_ARN  = aws_secretsmanager_secret.db.arn
      DB_CLUSTER_ARN = module.aurora.cluster_arn
      DB_NAME        = local.db_name
      DB_SCHEMA      = local.db_schema
      DB_TABLE       = local.db_table
    }
  }
  tags = {
    Name         = "RAG Ingest Lambda"
    Environment  = "Production"
    Project      = "RAG Portfolio Chat"
    "project-no" = "8"
  }
}

# Allow S3 to invoke Lambda
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingest.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.kb.arn

}

# -------------------------------
# 6. Init pgvector Extension (once)
# -------------------------------
resource "null_resource" "init_pgvector" {
  depends_on = [module.aurora]

  provisioner "local-exec" {
    command = <<EOT
      aws rds-data execute-statement \
        --resource-arn ${module.aurora.cluster_arn} \
        --secret-arn ${aws_secretsmanager_secret.db.arn} \
        --database ${var.db_name} \
        --sql "CREATE EXTENSION IF NOT EXISTS vector;"
      EOT
    environment = {
      AWS_REGION = "ap-south-1"
    }
  }

}

# -------------------------------
# 7. Lambda Function URL for Chat
# -------------------------------
resource "aws_lambda_function_url" "chat_url" {
  function_name      = aws_lambda_function.ingest.function_name
  authorization_type = "NONE"
  cors {
    allow_origins = ["*"]
    allow_methods = ["POST"]
  }

  depends_on = [aws_lambda_function.ingest]
}
