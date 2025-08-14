# Conditional Vercel deployment - only when token is provided
resource "vercel_project" "image_resizer" {
  count          = var.vercel_api_token != "" ? 1 : 0
  name           = "${var.project_name}-site"
  framework      = "nextjs"
  root_directory = "06-smart-resize-images/site"

  git_repository = {
    production_branch = "main"
    repo              = "omesh7/aws-portfolio"
    type              = "github"
  }
}

resource "vercel_project_environment_variable" "api_url" {
  count      = var.vercel_api_token != "" ? 1 : 0
  project_id = vercel_project.image_resizer[0].id
  key        = "IMAGE_RESIZE_API_URL"
  value      = aws_apigatewayv2_api.api.api_endpoint
  target     = ["production", "preview", "development"]
}


resource "vercel_deployment" "image_resizer_deploy" {
  count             = var.vercel_api_token != "" ? 1 : 0
  project_id        = vercel_project.image_resizer[0].id
  ref               = "main"
  production        = true
  delete_on_destroy = true

  depends_on = [
    vercel_project.image_resizer,
    vercel_project_environment_variable.api_url
  ]
}




output "vercel_deployment_url" {
  value       = var.vercel_api_token != "" ? vercel_deployment.image_resizer_deploy[0].domains[0] : null
  description = "The URL of the Vercel deployment for the image resize project"
  sensitive   = true
}
