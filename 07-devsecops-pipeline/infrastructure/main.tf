provider "aws" {
  region = var.aws_region
}

# --- Networking (Simplified for Demo) ---
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "devsecops-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  tags              = { Name = "devsecops-public-subnet" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# --- Security Groups ---
resource "aws_security_group" "ecs_tasks" {
  name   = "devsecops-ecs-tasks-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = 3000
    to_port     = 3000
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- IAM Roles ---
resource "aws_iam_role" "ecs_execution_role" {
  name = "devsecops-ecs-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- CloudWatch Logs ---
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/devsecops-app"
  retention_in_days = 7
}

# --- Modules ---
module "ecr" {
  source          = "./modules/ecr"
  repository_name = var.project_name
}

module "ecs" {
  source             = "./modules/ecs"
  cluster_name       = "${var.project_name}-cluster"
  app_name           = var.project_name
  container_image    = "${module.ecr.repository_url}:latest"
  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_execution_role.arn
  subnets            = [aws_subnet.public.id]
  security_group_id  = aws_security_group.ecs_tasks.id
  log_group_name     = aws_cloudwatch_log_group.app.name
  aws_region         = var.aws_region
}
