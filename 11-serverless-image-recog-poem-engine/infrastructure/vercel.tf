# Conditional Vercel deployment - only when token is provided
resource "vercel_project" "image_recog" {
  count          = var.vercel_api_token != "" ? 1 : 0
  name           = "${var.project_name}-site"
  framework      = "vite"
  root_directory = "11-serverless-image-recog-poem-engine/site"

  git_repository = {
    production_branch = "main"
    repo              = "omesh7/aws-portfolio"
    type              = "github"
  }
}



resource "vercel_project_environment_variables" "env_s" {
  count      = var.vercel_api_token != "" ? 1 : 0
  project_id = vercel_project.image_recog[0].id
  variables = [
    {
      key    = "VITE_UPLOADS_API_URL"
      value  = aws_lambda_function_url.uploads_url.function_url
      target = ["production", "preview", "development"]
    },
    {
      key    = "VITE_GET_POEM_API_URL"
      value  = aws_lambda_function_url.get_poem_url.function_url
      target = ["production", "preview", "development"]
    },
    {
      key    = "VITE_BUCKET_NAME"
      value  = aws_s3_bucket.main.bucket
      target = ["production", "preview", "development"]
  }]
}


resource "vercel_deployment" "image_recog_deploy" {
  count             = var.vercel_api_token != "" ? 1 : 0
  project_id        = vercel_project.image_recog[0].id
  ref               = "main"
  production        = true
  delete_on_destroy = true

  depends_on = [
    vercel_project.image_recog,
    vercel_project_environment_variables.env_s
  ]
}




output "vercel_deployment_url" {
  value       = var.vercel_api_token != "" ? vercel_deployment.image_recog_deploy[0].domains[0] : null
  description = "The URL of the Vercel deployment for the image Recog project"
  sensitive   = true
}



# Cloudflare DNS Record
resource "cloudflare_dns_record" "portfolio_dns" {
  zone_id = var.cloudflare_zone_id
  name    = var.cloudflare_site
  type    = "CNAME"
  content = var.vercel_api_token != "" ? "cname.vercel-dns.com" : "placeholder.vercel-dns.com"
  ttl     = 1
  proxied = true
}
