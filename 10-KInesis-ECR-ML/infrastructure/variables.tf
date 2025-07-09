variable "aws_region" { default = "ap-south-1" }
variable "project_name" { default = "" }
variable "vpc_cidr" {
  default = ""
  type    = string
}
variable "public_subnets_cidr" {
  type    = list(string)
  default = ["", ""]
}
variable "app_port" { default = 80 }
variable "min_tasks" { default = 1 }
variable "max_tasks" { default = 2 }

variable "ecr_repository_url" {
  description = "ECR repository URL for the FastAPI application"
  type        = string

}
