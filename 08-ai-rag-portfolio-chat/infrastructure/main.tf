terraform {
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 6.0" }
    random = { source = "hashicorp/random", version = "~> 3.0" }
  }
}

provider "aws" {
  region = var.aws_region
}

module "s3" {
  source = "./modules/s3"
  sku    = var.project_suffix
  tags   = var.tags
}

module "iam" {
  source     = "./modules/iam"
  bucket_arn = module.s3.bucket_arn
  tags       = var.tags
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/../lambda_08_project.zip"
}




module "lambda" {
  source         = "./modules/lambda"
  role_arn       = module.iam.role_arn
  bucket_name    = module.s3.bucket_name
  embed_model    = var.embed_model
  source_dir     = data.archive_file.lambda_zip.source_dir
  function_zip   = data.archive_file.lambda_zip.output_path
  tags           = var.tags
  project_suffix = var.project_suffix
}

resource "aws_s3_bucket_notification" "kb_notify" {
  bucket = module.s3.bucket_id
  lambda_function {
    lambda_function_arn = module.lambda.lambda_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "docs/"
  }
  depends_on = [module.lambda]
}


# --- Upload test file to trigger Lambda ---
resource "null_resource" "always_run" {
  triggers = {
    timestamp = timestamp()
  }
}

resource "aws_s3_object" "test_md_file" {
  bucket       = module.s3.bucket_name
  key          = "docs/test.md"
  source       = "${path.module}/test-docs/test.md"
  content_type = "text/markdown"

  depends_on = [
    aws_s3_bucket_notification.kb_notify,
    null_resource.always_run
  ]
}

