# Random hex for unique bucket naming
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "kb" {
  bucket        = "${var.sku}-kb-${random_id.bucket_suffix.hex}"
  force_destroy = true
  tags          = var.tags
}

output "bucket_id" {
  value = aws_s3_bucket.kb.id
}

output "bucket_name" {
  value = aws_s3_bucket.kb.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.kb.arn
}
