variable "aws_region" {
  description = "The AWS region where resources will be created"
  type        = string
  default     = "us-east-1"

}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {

    Project = "test-lex-bot"
  }
}


variable "vpc_id" {
  description = "The VPC ID where the resources will be created"
  type        = string
  default     = ""

}

variable "subnet_ids" {
  description = "List of subnet IDs where the resources will be created"
  type        = list(string)
  default     = []

}
