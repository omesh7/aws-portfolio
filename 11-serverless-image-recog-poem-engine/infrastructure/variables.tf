variable "aws_region" { default = "ap-south-1" }
variable "project_name" { default = "" }
variable "tags" {
  default = {
    Environment = "Portfolio"
    Project     = "serverless-11-image-recog-poem"
    project-no  = "11"
  }
  type = map(string)
}
variable "bedrock_model_id" {
  default = "amazon.titan-text-lite-v1"
}
