# Outputs
output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.app.repository_url
}

output "load_balancer_dns" {
  description = "Load balancer DNS name"
  value       = aws_lb.app.dns_name
}

output "application_url" {
  description = "Application URL"
  value       = "http://${aws_lb.app.dns_name}/summarize?url=jNQXAC9IVRw"
}