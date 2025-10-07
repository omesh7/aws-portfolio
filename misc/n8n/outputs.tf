output "n8n_url" {
  description = "The final URL to access your n8n instance"
  value       = "https://${var.n8n_hostname}"
}

output "load_balancer_dns" {
  description = "The direct DNS address of the AWS Application Load Balancer"
  value       = "https://${module.n8n.lb_dns_name}"
}

output "certificate_arn" {
  description = "ACM certificate ARN for debugging"
  value       = aws_acm_certificate.n8n_cert.arn
}

output "certificate_status" {
  description = "Certificate validation status"
  value       = aws_acm_certificate_validation.n8n_cert_validation.certificate_arn
}