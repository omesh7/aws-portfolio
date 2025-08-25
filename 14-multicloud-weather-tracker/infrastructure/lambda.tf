resource "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../backend"
  output_path = "${path.module}/../lambda_14.zip"

}

# Random hex for unique resource naming
resource "random_id" "resource_suffix" {
  byte_length = 4
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-lambda-exec-role-${random_id.resource_suffix.hex}"

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

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_exec.name
}


resource "aws_lambda_function" "weather_tracker" {
  function_name    = "${var.project_name}-weather-tracker-${random_id.resource_suffix.hex}"
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  role             = aws_iam_role.lambda_exec.arn
  filename         = archive_file.lambda_zip.output_path
  source_code_hash = archive_file.lambda_zip.output_base64sha256
  memory_size      = 128
  package_type     = "Zip"
  environment {
    variables = {
      OPENWEATHER_API_KEY = var.openweather_api_key
      DOMAIN_NAME         = "${var.subdomain}.${data.cloudflare_zone.zone.name}"
      CLOUDFRONT_DOMAIN   = module.aws_infrastructure.cloudfront_domain
    }
  }
  ephemeral_storage {
    size = 512
  }

  tags = {
    Name = "${var.project_name}-weather-tracker"
  }
}

resource "aws_lambda_function_url" "weather_tracker_url" {
  function_name      = aws_lambda_function.weather_tracker.arn
  authorization_type = "NONE"

  cors {
    allow_origins = [
      "https://weather.portfolio.omesh.site"
    ]
    allow_methods = ["GET", "POST"]
    allow_headers = ["Content-Type"]
    max_age       = 86400
  }
}


output "aws_lambda_function_url_weather_tracker_url" {
  value = aws_lambda_function_url.weather_tracker_url.function_url
}

