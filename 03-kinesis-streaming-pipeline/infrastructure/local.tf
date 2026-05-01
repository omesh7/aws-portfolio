locals {
  use_local_archive          = var.environment == "local"
  lambda_kinesis_filename    = local.use_local_archive ? data.archive_file.kinesis_lambda[0].output_path : var.lambda_kinesis_zip_path
  lambda_kinesis_source_hash = local.use_local_archive ? data.archive_file.kinesis_lambda[0].output_base64sha256 : (fileexists(var.lambda_kinesis_zip_path) ? filebase64sha256(var.lambda_kinesis_zip_path) : "")
}


data "archive_file" "kinesis_lambda" {
  count       = local.use_local_archive ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/../lambda_10_project.zip"
}
