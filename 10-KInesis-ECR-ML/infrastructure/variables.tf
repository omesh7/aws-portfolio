variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "10-kinesis-ecr-ml"
}

variable "environment" {
  description = "Environment (local or ci)"
  type        = string
  default     = "local"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets_cidr" {
  description = "Public subnets CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 80
}

variable "min_tasks" {
  description = "Minimum number of ECS tasks"
  type        = number
  default     = 1
}

variable "max_tasks" {
  description = "Maximum number of ECS tasks"
  type        = number
  default     = 2
}

variable "ecr_repository_url" {
  description = "ECR repository URL for the FastAPI application"
  type        = string
}

variable "image_version" {
  description = "Version of the Docker image to be used in ECS"
  type        = string
  default     = "latest"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "Portfolio"
    Owner       = "Omesh"
    Project     = "kinesis-ecr-10-app"
    project-no  = "10"
  }
}

variable "lambda_kinesis_zip_path" {
  description = "Path to the Kinesis Lambda zip file"
  type        = string

}
