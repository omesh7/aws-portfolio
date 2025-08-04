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

resource "vercel_deployment" "image_Resize_project_deploy" {
  project_id        = vercel_project.image_Resize_project.id
  ref               = "main" # or a git branch
  production        = true
  delete_on_destroy = true

  depends_on = [
    vercel_project.image_Resize_project,
    vercel_project_environment_variable.lambda_url
  ]
}

output "vercel_deployment_url" {
  value       = vercel_deployment.image_Resize_project_deploy.domains[0]
  description = "The URL of the Vercel deployment for the image resize project"

}
