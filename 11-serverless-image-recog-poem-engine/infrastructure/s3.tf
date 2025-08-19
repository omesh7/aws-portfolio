# -------------------------------
# S3 Bucket Configuration
# -------------------------------
resource "aws_s3_bucket" "main" {
  bucket        = local.bucket_name_prefix
  force_destroy = true
}

# CORS configuration for S3 bucket
resource "aws_s3_bucket_cors_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "POST", "PUT"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Lifecycle rule to auto-expire objects in the uploads folder
resource "aws_s3_bucket_lifecycle_configuration" "uploads_expiration" {
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "expire-uploads-after-5min"
    status = "Enabled"

    filter {
      prefix = local.uploads_prefix
    }

    expiration {
      days = local.expiration_days
    }
  }
}

# Create S3 folders by creating zero-byte objects
resource "aws_s3_object" "uploads_folder" {
  bucket        = aws_s3_bucket.main.bucket
  key           = local.uploads_prefix
  force_destroy = true
}

resource "aws_s3_object" "poems_folder" {
  bucket        = aws_s3_bucket.main.bucket
  key           = local.poems_prefix
  force_destroy = true
}

# -------------------------------
# S3 Bucket Notification
# -------------------------------
resource "aws_s3_bucket_notification" "upload_trigger" {
  bucket = aws_s3_bucket.main.bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.image_recog.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = local.uploads_prefix
    filter_suffix       = ".jpg"
  }

  lambda_function {
    lambda_function_arn = aws_lambda_function.image_recog.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = local.uploads_prefix
    filter_suffix       = ".jpeg"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}