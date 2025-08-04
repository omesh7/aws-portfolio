variable "aws_region" {
  description = "AWS region for primary deployment"
  type        = string
  default     = "ap-south-1"
}

variable "azure_location" {
  description = "Azure location for secondary deployment"
  type        = string
  default     = "East US"
}

variable "azure_resource_group" {
  description = "Azure resource group name"
  type        = string
  default     = "weather-tracker-rg"
}

variable "project_name" {
  description = "The name of the project, used for naming resources."
  type        = string
  default     = "14-weather-app-aws-portfolio"
}

variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare API token"
  sensitive   = true
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare Zone ID"
  sensitive   = true
}

variable "subdomain" {
  type        = string
  description = "Subdomain to point to weather app"
  default     = "weather.portfolio"
}

variable "project_owner" {
  description = "The owner of the project, used for tagging resources."
  type        = string
  default     = ""
}

variable "environment" {
  description = "The environment for the project (e.g., dev, staging, prod)."
  type        = string
  default     = "portfolio"
}


variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "14-weather-app-aws-portfolio"
    Environment = "portfolio"
    Owner       = "omesh"
    Description = "Weather Tracker Application"
    project-no  = "14"
  }
}



variable "openweather_api_key" {
  description = "OpenWeather API key for weather data"
  type        = string
  sensitive   = true
  default     = ""
}
