variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "project-13-2048-game-cp"
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
    Project     = "13-2048-game-codepipeline"
    ProjectNo   = "13"
  }
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 8080
}
