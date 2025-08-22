variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "proj-13-2048-game-cp"
}

variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Default tags for resources"
  type        = map(string)
  default = {
    Environment = "Portfolio"
    Project     = "13-2048-game-aws-codepipeline"
    ProjectNo   = "13"
  }
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 8080
}

variable "grafana_url" {
  description = "Grafana instance URL (e.g., https://your-org.grafana.net)"
  type        = string
}

variable "grafana_auth" {
  description = "Grafana API key for authentication"
  type        = string
  sensitive   = true
}

variable "aws_role_arn" {
  description = "AWS IAM role ARN for Grafana CloudWatch access"
  type        = string
  sensitive   = true
  #https://YOUR_GRAFANA_INSTANCE.grafana.net/a/grafana-csp-app/aws/configuration/accounts/create
}


