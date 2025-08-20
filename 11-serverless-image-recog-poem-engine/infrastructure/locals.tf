# -------------------------------
# Locals
# -------------------------------
locals {
  bucket_name_prefix = "11-serverless-image-recog-poem-bucket-${random_id.bucket_suffix.hex}"
  uploads_prefix     = "uploads/"
  poems_prefix       = "poems/"
  lambda_env_vars = {
    ENVIRONMENT      = "Portfolio"
    LOG_LEVEL        = "INFO"
    BUCKET_NAME      = "11-serverless-image-recog-poem-bucket-${random_id.bucket_suffix.hex}"
    TABLE_NAME       = "${var.project_name}-poem-results"
    BEDROCK_MODEL_ID = var.bedrock_model_id
  }
  use_local_archive           = var.environment == "local"
  lambda_uploads_filename     = local.use_local_archive ? data.archive_file.uploads_lambda[0].output_path : var.lambda_uploads_zip_path
  lambda_image_recog_filename = local.use_local_archive ? data.archive_file.image_recog_lambda[0].output_path : var.lambda_image_recog_zip_path
  lambda_get_poem_filename    = local.use_local_archive ? data.archive_file.get_poem_lambda[0].output_path : var.lambda_get_poem_zip_path

  lambda_uploads_source_hash     = local.use_local_archive ? data.archive_file.uploads_lambda[0].output_base64sha256 : (fileexists(var.lambda_uploads_zip_path) ? filebase64sha256(var.lambda_uploads_zip_path) : "")
  lambda_image_recog_source_hash = local.use_local_archive ? data.archive_file.image_recog_lambda[0].output_base64sha256 : (fileexists(var.lambda_image_recog_zip_path) ? filebase64sha256(var.lambda_image_recog_zip_path) : "")
  lambda_get_poem_source_hash    = local.use_local_archive ? data.archive_file.get_poem_lambda[0].output_base64sha256 : (fileexists(var.lambda_get_poem_zip_path) ? filebase64sha256(var.lambda_get_poem_zip_path) : "")

  lambda_memory   = 128
  expiration_days = 1
}

# -------------------------------
# Random ID for unique bucket naming
# -------------------------------
resource "random_id" "bucket_suffix" {
  byte_length = 4
}