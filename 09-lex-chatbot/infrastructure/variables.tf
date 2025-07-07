variable "aws_region" {
  description = "The AWS region where resources will be created"
  type        = string
  default     = "us-east-1"

}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    project-no = "9"
    Project    = "09-lex-chatbot"
  }
}
