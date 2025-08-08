resource "aws_cognito_user_pool" "user_pool" {
  name = "${var.project_name}-user-pool"
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  name            = "${var.project_name}-frontend-client"
  user_pool_id    = aws_cognito_user_pool.user_pool.id
  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_CUSTOM_AUTH"
  ]
}

resource "aws_cognito_user" "test_user" {
  user_pool_id = aws_cognito_user_pool.user_pool.id
  username     = "omesh"
  password     = "2RiO+Y5Oli_r"

  attributes = {
    email = "omesh845@gmail.com"
  }

  lifecycle {
    ignore_changes = [password]
  }
}

output "vite_env" {
  value = {
    VITE_API_ENDPOINT        = aws_lambda_function_url.url.function_url
    VITE_API_REGION          = var.aws_region
    VITE_USER_POOL_ID        = aws_cognito_user_pool.user_pool.id
    VITE_USER_POOL_CLIENT_ID = aws_cognito_user_pool_client.user_pool_client.id
  }
}
