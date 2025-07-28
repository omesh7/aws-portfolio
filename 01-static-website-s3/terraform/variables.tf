variable "aws_region" {
  description = "The AWS region where the S3 bucket will be created."
  type        = string
  default     = "ap-south-1"

}

variable "project_name" {
  description = "The name of the project, used for naming resources."
  type        = string
  default     = "01-project-aws-portfolio"

}

variable "github_deploy_user_arn" {
  description = "The ARN of the GitHub deploy user."
  type        = string
  default     = "" # Set this to the actual ARN of your GitHub deploy user
}

