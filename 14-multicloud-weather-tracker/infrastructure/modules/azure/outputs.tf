output "storage_account_name" {
  description = "Name of the Azure storage account"
  value       = azurerm_storage_account.website.name
}

output "cdn_endpoint_url" {
  description = "Azure CDN endpoint URL"
  value       = "https://${azurerm_cdn_endpoint.website.fqdn}"
}

output "cdn_endpoint_fqdn" {
  description = "Azure CDN endpoint FQDN"
  value       = azurerm_cdn_endpoint.website.fqdn
}