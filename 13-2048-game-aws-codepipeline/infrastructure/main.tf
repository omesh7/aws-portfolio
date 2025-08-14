# Main Terraform configuration for 2048 Game CI/CD Pipeline
# This file defines the core AWS infrastructure components

terraform {
  cloud {
    organization = "aws-portfolio-omesh"
    workspaces {
      name = "13-2048-game-aws-codepipeline"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Configure AWS provider with default tags for resource management
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = var.tags
  }
}

# Random string for unique resource naming to avoid conflicts
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# ============================================================================
# CONTAINER REGISTRY
# ============================================================================

# ECR repository to store Docker images for the Flask API
resource "aws_ecr_repository" "game_2048" {
  name                 = "${var.project_name}-repo-${random_string.suffix.result}"
  image_tag_mutability = "MUTABLE" # Allow overwriting image tags
  force_delete         = true      # Allow deletion even with images

  # Enable vulnerability scanning for security
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-ecr-repo"
    Description = "Container registry for 2048 game Flask API"
  }
}

# ============================================================================
# STATIC WEBSITE HOSTING
# ============================================================================

# S3 bucket for hosting the React frontend as a static website
resource "aws_s3_bucket" "frontend" {
  bucket        = "${var.project_name}-frontend"
  force_destroy = true # Allow deletion even with objects
}

# Configure S3 bucket for static website hosting
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  # Handle React Router by redirecting all errors to index.html
  error_document {
    key = "index.html"
  }
}

# Allow public access to the S3 bucket for static website hosting
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy to allow public read access for static website
resource "aws_s3_bucket_policy" "frontend" {
  bucket     = aws_s3_bucket.frontend.id
  depends_on = [aws_s3_bucket_public_access_block.frontend]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })
}

# ============================================================================
# NETWORKING
# ============================================================================

# Get available AZs for multi-AZ deployment
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC for isolating our resources
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true # Required for ECS
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Description = "VPC for 2048 game infrastructure"
  }
}

# Internet Gateway for public internet access
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public subnets in different AZs for high availability
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true # Auto-assign public IPs

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
    Type = "Public"
  }
}

# Route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # Route all traffic to Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Associate public subnets with route table
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ============================================================================
# SECURITY GROUPS
# ============================================================================

# Security group for Application Load Balancer
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-alb-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for Application Load Balancer"

  # Allow HTTP traffic from internet
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-alb-sg"
    Description = "Security group for ALB - allows HTTP from internet"
  }
}

# Security group for ECS service
resource "aws_security_group" "ecs_service" {
  name_prefix = "${var.project_name}-ecs-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for ECS service"

  # Allow traffic from ALB only on application port
  ingress {
    description     = "HTTP from ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Allow all outbound traffic (for ECR pulls, etc.)
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-ecs-sg"
    Description = "Security group for ECS - allows traffic from ALB only"
  }
}

# ============================================================================
# LOAD BALANCER
# ============================================================================

# Application Load Balancer for distributing traffic to ECS tasks
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false # Internet-facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  # Enable deletion protection in production
  enable_deletion_protection = false

  tags = {
    Name        = "${var.project_name}-alb"
    Description = "Application Load Balancer for 2048 game API"
  }
}

# Target group for ECS tasks
resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip" # Required for Fargate

  # Health check configuration
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/" # Flask app health endpoint
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.project_name}-tg"
    Description = "Target group for ECS tasks"
  }
}

# ALB listener to forward traffic to target group
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  tags = {
    Name = "${var.project_name}-listener"
  }
}

# ============================================================================
# ECS CLUSTER AND SERVICE
# ============================================================================

# ECS cluster for running containerized applications
resource "aws_ecs_cluster" "game_cluster" {
  name = "${var.project_name}-cluster"

  # Enable container insights for monitoring
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.project_name}-cluster"
    Description = "ECS cluster for 2048 game"
  }
}

# IAM role for ECS task execution (required for Fargate)
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-ecs-execution-role"
    Description = "IAM role for ECS task execution"
  }
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# CloudWatch log group for ECS tasks
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 3 # Keep logs for 30 days

  tags = {
    Name        = "${var.project_name}-logs"
    Description = "CloudWatch logs for ECS tasks"
  }
}

# ECS task definition for the Flask API
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-task"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc" # Required for Fargate
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256 # 0.25 vCPU
  memory                   = 512 # 512 MB

  # Container definition for Flask API
  container_definitions = jsonencode([
    {
      name  = "game-api"
      image = "${aws_ecr_repository.game_2048.repository_url}:latest"

      # Port mapping for Flask app
      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = var.app_port
          protocol      = "tcp"
        }
      ]

      # Environment variables
      environment = [
        {
          name  = "ENVIRONMENT"
          value = "production"
        }
      ]

      # CloudWatch logging configuration
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      # Health check
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.app_port}/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-task-def"
    Description = "ECS task definition for Flask API"
  }
}

# ECS service to run and maintain desired number of tasks
resource "aws_ecs_service" "main" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.game_cluster.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  # Network configuration for Fargate
  network_configuration {
    security_groups  = [aws_security_group.ecs_service.id]
    subnets          = aws_subnet.public[*].id
    assign_public_ip = true # Required for ECR image pulls
  }

  # Load balancer configuration
  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "game-api"
    container_port   = var.app_port
  }

  # Ensure ALB listener is created before service
  depends_on = [aws_lb_listener.web]

  tags = {
    Name        = "${var.project_name}-service"
    Description = "ECS service for 2048 game API"
  }
}
