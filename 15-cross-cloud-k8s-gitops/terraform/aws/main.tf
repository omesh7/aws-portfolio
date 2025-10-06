
# VPC - isolated network for Kubernetes cluster 
resource "aws_vpc" "k8s_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "k8s-crosscloud-vpc"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# Internet Gateway for public access
resource "aws_internet_gateway" "k8s_igw" {
  vpc_id = aws_vpc.k8s_vpc.id
  tags = { Name = "k8s-crosscloud-igw" }
}

# Subnets
resource "aws_subnet" "k8s_subnets" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "k8s-subnet-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/elb" = "1"
  }
}

# Route Table
resource "aws_route_table" "k8s_rt" {
  vpc_id = aws_vpc.k8s_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s_igw.id
  }
  tags = { Name = "k8s-crosscloud-rt" }
}

resource "aws_route_table_association" "k8s_rta" {
  count          = length(aws_subnet.k8s_subnets)
  subnet_id      = aws_subnet.k8s_subnets[count.index].id
  route_table_id = aws_route_table.k8s_rt.id
}

# Security Groups
resource "aws_security_group" "k8s_master" {
  name_prefix = "k8s-master-"
  vpc_id      = aws_vpc.k8s_vpc.id

  # Kubernetes API
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Internal cluster communication
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "k8s-master-sg" }
}

resource "aws_security_group" "k8s_worker" {
  name_prefix = "k8s-worker-"
  vpc_id      = aws_vpc.k8s_vpc.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NodePort services
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Internal cluster communication
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "k8s-worker-sg" }
}

# IAM Role for EC2 instances
resource "aws_iam_role" "k8s_node_role" {
  name = "k8s-crosscloud-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "k8s_node_policy" {
  name = "k8s-crosscloud-node-policy"
  role = aws_iam_role.k8s_node_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "k8s_node_profile" {
  name = "k8s-crosscloud-node-profile"
  role = aws_iam_role.k8s_node_role.name
}

# Key Pair
resource "aws_key_pair" "k8s_key" {
  key_name   = "k8s-crosscloud-key"
  public_key = file(var.public_key_path)
}

# Master Nodes
resource "aws_instance" "k8s_masters" {
  count                  = var.master_count
  ami                    = var.ami_id
  instance_type          = var.master_instance_type
  key_name               = aws_key_pair.k8s_key.key_name
  vpc_security_group_ids = [aws_security_group.k8s_master.id]
  subnet_id              = aws_subnet.k8s_subnets[count.index % length(aws_subnet.k8s_subnets)].id
  iam_instance_profile   = aws_iam_instance_profile.k8s_node_profile.name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    node_type = "master"
  }))

  tags = {
    Name = "k8s-master-${count.index + 1}"
    Role = "master"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# Worker Nodes
resource "aws_instance" "k8s_workers" {
  count                  = var.worker_count
  ami                    = var.ami_id
  instance_type          = var.worker_instance_type
  key_name               = aws_key_pair.k8s_key.key_name
  vpc_security_group_ids = [aws_security_group.k8s_worker.id]
  subnet_id              = aws_subnet.k8s_subnets[count.index % length(aws_subnet.k8s_subnets)].id
  iam_instance_profile   = aws_iam_instance_profile.k8s_node_profile.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    node_type = "worker"
  }))

  tags = {
    Name = "k8s-worker-${count.index + 1}"
    Role = "worker"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# Load Balancer for API Server
resource "aws_lb" "k8s_api" {
  name               = "k8s-api-lb"
  internal           = false
  load_balancer_type = "network"
  subnets            = aws_subnet.k8s_subnets[*].id

  tags = { Name = "k8s-api-lb" }
}

resource "aws_lb_target_group" "k8s_api" {
  name     = "k8s-api-tg"
  port     = 6443
  protocol = "TCP"
  vpc_id   = aws_vpc.k8s_vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/healthz"
    port                = "traffic-port"
    protocol            = "HTTPS"
    timeout             = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "k8s_api" {
  count            = length(aws_instance.k8s_masters)
  target_group_arn = aws_lb_target_group.k8s_api.arn
  target_id        = aws_instance.k8s_masters[count.index].id
  port             = 6443
}

resource "aws_lb_listener" "k8s_api" {
  load_balancer_arn = aws_lb.k8s_api.arn
  port              = "6443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_api.arn
  }
}