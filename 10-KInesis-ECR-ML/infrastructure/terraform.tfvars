project_name        = "kinesis-ecr-10-app"
aws_region          = "ap-south-1"
vpc_cidr            = "10.0.0.0/16"
public_subnets_cidr = ["10.0.1.0/24", "10.0.2.0/24"]
app_port            = 80
min_tasks           = 1
max_tasks           = 2
