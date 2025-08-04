variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "06-resized-images-bucket-aws-portfolio"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "vercel_api_token" {
  description = "Vercel API token for deployment"
  type        = string
  default     = ""

}

variable "team" {
  description = "Vercel team identifier"
  type        = string
  default     = ""

}


variable "vercel_project_name" {

  description = "Project ID for Vercel deployment"
  type        = string
  default     = ""
}


variable "vercel_project_id" {
  description = "Project ID for Vercel deployment"
  type        = string
  default     = ""

}
