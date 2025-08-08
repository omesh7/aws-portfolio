resource "aws_s3_bucket" "main_bucket" {
  bucket        = "${var.project_name}-bucket"
  force_destroy = true
}

resource "aws_s3_bucket_notification" "kb_notify" {
  bucket = aws_s3_bucket.main_bucket.bucket
  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "docs/"
  }
  depends_on = [aws_lambda_function.lambda_function]

}


output "bucket_name" {
  value = aws_s3_bucket.main_bucket.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.main_bucket.arn

}
