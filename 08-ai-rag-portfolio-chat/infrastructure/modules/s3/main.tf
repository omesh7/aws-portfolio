resource "aws_s3_bucket" "kb" {
  bucket        = "${var.sku}-kb"
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
