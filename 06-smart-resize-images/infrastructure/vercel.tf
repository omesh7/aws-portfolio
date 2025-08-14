# Conditional Vercel deployment - only when token is provided
resource "vercel_project" "image_resizer" {
  count     = var.vercel_api_token != "" ? 1 : 0
  name      = "${var.project_name}-site"
  framework = "nextjs"
}

resource "vercel_project_environment_variable" "api_url" {
  count      = var.vercel_api_token != "" ? 1 : 0
  project_id = vercel_project.image_resizer[0].id
  key        = "IMAGE_RESIZE_API_URL"
  value      = aws_apigatewayv2_api.api.api_endpoint
  target     = ["production", "preview", "development"]
}

output "vercel_project_id" {
  value     = var.vercel_api_token != "" ? vercel_project.image_resizer[0].id : null
  sensitive = true
}

output "vercel_url" {
  value     = var.vercel_api_token != "" ? "https://${vercel_project.image_resizer[0].name}.vercel.app" : null
  sensitive = true
}
