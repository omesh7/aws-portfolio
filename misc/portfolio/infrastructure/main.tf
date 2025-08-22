# Vercel Project
resource "vercel_project" "portfolio" {
  count          = var.vercel_api_token != "" ? 1 : 0
  name           = var.project_name
  framework      = "nextjs"
  root_directory = "misc/portfolio/site"

  git_repository = {
    production_branch = "main"
    repo              = "omesh7/aws-portfolio"
    type              = "github"
  }
}

# Environment Variables
resource "vercel_project_environment_variable" "emailjs_service_id" {
  count      = var.vercel_api_token != "" ? 1 : 0
  project_id = vercel_project.portfolio[0].id
  key        = "NEXT_PUBLIC_EMAILJS_SERVICE_ID"
  value      = var.emailjs_service_id
  target     = ["production", "preview", "development"]
}

resource "vercel_project_environment_variable" "emailjs_template_id" {
  count      = var.vercel_api_token != "" ? 1 : 0
  project_id = vercel_project.portfolio[0].id
  key        = "NEXT_PUBLIC_EMAILJS_TEMPLATE_ID"
  value      = var.emailjs_template_id
  target     = ["production", "preview", "development"]
}

resource "vercel_project_environment_variable" "emailjs_public_key" {
  count      = var.vercel_api_token != "" ? 1 : 0
  project_id = vercel_project.portfolio[0].id
  key        = "NEXT_PUBLIC_EMAILJS_PUBLIC_KEY"
  value      = var.emailjs_public_key
  target     = ["production", "preview", "development"]
}

# Vercel Deployment
resource "vercel_deployment" "portfolio_deploy" {
  count             = var.vercel_api_token != "" ? 1 : 0
  project_id        = vercel_project.portfolio[0].id
  ref               = "main"
  production        = true
  delete_on_destroy = true

  depends_on = [
    vercel_project.portfolio,
    vercel_project_environment_variable.emailjs_service_id,
    vercel_project_environment_variable.emailjs_template_id,
    vercel_project_environment_variable.emailjs_public_key
  ]
}

# Custom Domain
resource "vercel_project_domain" "portfolio_domain" {
  count      = var.vercel_api_token != "" ? 1 : 0
  project_id = vercel_project.portfolio[0].id
  domain     = "${var.subdomain}.${data.cloudflare_zone.zone.name}"

  depends_on = [vercel_project.portfolio]
}

# Cloudflare DNS Record
resource "cloudflare_dns_record" "portfolio_dns" {
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  type    = "CNAME"
  content = var.vercel_api_token != "" ? "cname.vercel-dns.com" : "placeholder.vercel-dns.com"
  ttl     = 60
  proxied = true
}
