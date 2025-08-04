resource "vercel_project" "image_Resize_project" {
  name                                 = var.vercel_project_name
  framework                            = "nextjs"
  root_directory                       = "06-smart-resize-images/site"
  enable_affected_projects_deployments = true

  git_repository = {
    production_branch = "main"
    repo              = "omesh7/aws-portfolio"
    type              = "github"
  }
}

resource "vercel_project_environment_variable" "lambda_url" {
  project_id = vercel_project.image_Resize_project.id
  key        = "IMAGE_RESIZE_API_URL"
  value      = aws_apigatewayv2_stage.default.invoke_url
  target     = ["production", "preview", "development"]
  sensitive  = false
}
