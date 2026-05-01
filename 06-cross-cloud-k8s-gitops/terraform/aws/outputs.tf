output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.k8s_vpc.id
}

output "subnet_ids" {
  description = "IDs of the subnets"
  value       = aws_subnet.k8s_subnets[*].id
}

output "master_ips" {
  description = "Public IP addresses of master nodes"
  value       = aws_instance.k8s_masters[*].public_ip
}

output "worker_ips" {
  description = "Public IP addresses of worker nodes"
  value       = aws_instance.k8s_workers[*].public_ip
}

output "master_private_ips" {
  description = "Private IP addresses of master nodes"
  value       = aws_instance.k8s_masters[*].private_ip
}

output "worker_private_ips" {
  description = "Private IP addresses of worker nodes"
  value       = aws_instance.k8s_workers[*].private_ip
}

output "api_server_endpoint" {
  description = "Kubernetes API server endpoint"
  value       = aws_lb.k8s_api.dns_name
}

output "bastion_ip" {
  description = "Bastion host IP (first master)"
  value       = aws_instance.k8s_masters[0].public_ip
}