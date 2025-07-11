# output "ecr_repository_url" {
#   value = aws_ecr_repository.repo.repository_url

# }

output "alb_dns" {
  value = aws_lb.alb.dns_name
}

