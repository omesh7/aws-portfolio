output "vercel_deployment_url" {
  value       = var.vercel_api_token != "" ? vercel_deployment.portfolio_deploy[0].domains[0] : null
  description = "The URL of the Vercel deployment"
  sensitive   = true
}

output "custom_domain_url" {
  value       = "https://${var.subdomain}.${data.cloudflare_zone.zone.name}"
  description = "The custom domain URL"
}

output "vercel_project_id" {
  value       = var.vercel_api_token != "" ? vercel_project.portfolio[0].id : null
  description = "Vercel project ID"
  sensitive   = true
}
