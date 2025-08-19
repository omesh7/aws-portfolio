# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group
  location = var.azure_location
}

# Storage Account for static website
resource "azurerm_storage_account" "website" {
  name                     = replace(replace(var.domain_name, ".", ""), "-", "")
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  tags = {
    environment = "production"
    project     = "weather-tracker"
  }
}

resource "azurerm_storage_account_static_website" "website" {
  storage_account_id = azurerm_storage_account.website.id
  index_document     = "index.html"
  error_404_document = "error.html"
}

# CDN Profile
resource "azurerm_cdn_profile" "website" {
  name                = "${replace(var.domain_name, ".", "-")}-cdn"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard_Microsoft"
}

# CDN Endpoint
resource "azurerm_cdn_endpoint" "website" {
  name                = "${replace(var.domain_name, ".", "-")}-endpoint"
  profile_name        = azurerm_cdn_profile.website.name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  origin {
    name      = "storage"
    host_name = azurerm_storage_account.website.primary_web_host
  }

  origin_host_header = azurerm_storage_account.website.primary_web_host

  delivery_rule {
    name  = "httpsRedirect"
    order = 1

    request_scheme_condition {
      operator     = "Equal"
      match_values = ["HTTP"]
    }

    url_redirect_action {
      redirect_type = "Found"
      protocol      = "Https"
    }
  }

  tags = {
    environment = "production"
    project     = "weather-tracker"
  }
}