provider "aws" {
  region = var.aws_region
}

# --- VPC & Networking (Simplified) ---
data "aws_vpc" "default" { default = true }
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- Security Group ---
resource "aws_security_group" "web" {
  name        = "ansible-web-sg"
  description = "Allow SSH and Web traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from runner"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ansible-web-sg" }
}

# --- SSH Key Pair ---
resource "aws_key_pair" "deployer" {
  key_name   = "ansible-deployer-key"
  public_key = var.public_key
}

# --- EC2 Instances ---
resource "aws_instance" "web" {
  count         = 2
  ami           = var.ami_id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.deployer.key_name
  
  vpc_security_group_ids = [aws_security_group.web.id]
  subnet_id              = data.aws_subnets.default.ids[0]

  tags = {
    Name        = "ansible-web-${count.index + 1}"
    Environment = "staging"
    Role        = "webserver"
  }
}

# --- Variables ---
variable "aws_region" { default = "ap-south-1" }
variable "allowed_ssh_cidr" { default = "0.0.0.0/0" } # Should be restricted in prod
variable "public_key" { type = string }
variable "ami_id" { 
  description = "Amazon Linux 2023 AMI"
  default     = "ami-053b12d3152c0cc71" # ap-south-1 AL2023
}

# --- Outputs ---
output "instance_ips" {
  value = aws_instance.web[*].public_ip
}
output "instance_ids" {
  value = aws_instance.web[*].id
}
