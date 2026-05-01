variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "execution_role_arn" {
  description = "ARN of the ECS execution role"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the ECS task role"
  type        = string
}

variable "vault_image" {
  description = "Docker image for Vault"
  type        = string
  default     = "hashicorp/vault:1.15"
}

variable "domain_name" {
  description = "Domain name for Vault ALB"
  type        = string
}

# --- DynamoDB Storage Backend ---
resource "aws_dynamodb_table" "vault_storage" {
  name         = "${var.project_name}-vault-storage"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Path"
  range_key    = "Key"

  attribute {
    name = "Path"
    type = "S"
  }

  attribute {
    name = "Key"
    type = "S"
  }

  tags = {
    Name = "${var.project_name}-vault-storage"
  }
}

# --- KMS Key for Auto-Unseal ---
resource "aws_kms_key" "vault_unseal" {
  description             = "KMS key for Vault auto-unseal"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Vault Task Role to use the key"
        Effect = "Allow"
        Principal = {
          AWS = var.task_role_arn
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

# --- Secrets Manager for Root Token ---
resource "aws_secretsmanager_secret" "vault_root_token" {
  name        = "${var.project_name}/vault-root-token"
  description = "Vault root token (populated after initialization)"
}

# --- Application Load Balancer ---
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for Vault ALB"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnets
}

resource "aws_lb_target_group" "vault" {
  name        = "${var.project_name}-tg"
  port        = 8200
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/v1/sys/health"
    matcher             = "200,429" # 429 is returned when uninitialized/sealed
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# ACM Certificate (Request only, user needs to validate)
resource "aws_acm_certificate" "vault" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.vault.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vault.arn
  }
}

# --- ECS Fargate Cluster & Service ---
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project_name}-ecs-tasks-sg"
  description = "Security group for Vault ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 8200
    to_port         = 8200
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_log_group" "vault" {
  name              = "/ecs/${var.project_name}-vault"
  retention_in_days = 30
}

resource "aws_ecs_task_definition" "vault" {
  family                   = "${var.project_name}-vault"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "vault"
      image     = var.vault_image
      essential = true
      portMappings = [
        {
          containerPort = 8200
          hostPort      = 8200
        }
      ]
      environment = [
        { name = "VAULT_LOCAL_CONFIG", value = jsonencode({
          storage = {
            dynamodb = {
              region     = data.aws_region.current.name
              table      = aws_dynamodb_table.vault_storage.name
              ha_enabled = "true"
            }
          }
          seal = {
            awskms = {
              region     = data.aws_region.current.name
              kms_key_id = aws_kms_key.vault_unseal.key_id
            }
          }
          listener = {
            tcp = {
              address     = "0.0.0.0:8200"
              tls_disable = "true"
            }
          }
          ui = true
          api_addr = "https://${var.domain_name}"
          cluster_addr = "http://127.0.0.1:8201"
        }) }
      ]
      command = ["server"]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.vault.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "vault"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "vault" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.vault.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.ecs_tasks.id]
    subnets         = var.private_subnets
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.vault.arn
    container_name   = "vault"
    container_port   = 8200
  }

  depends_on = [aws_lb_listener.https]
}

data "aws_region" "current" {}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.vault_storage.arn
}

output "kms_key_arn" {
  value = aws_kms_key.vault_unseal.arn
}

output "secrets_manager_arn" {
  value = aws_secretsmanager_secret.vault_root_token.arn
}
