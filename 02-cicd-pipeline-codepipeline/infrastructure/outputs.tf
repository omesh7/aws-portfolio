output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.game_2048.repository_url
}

output "api_url" {
  description = "API URL (Load Balancer)"
  value       = "http://${aws_lb.main.dns_name}"
}

output "s3_bucket_name" {
  description = "S3 bucket name for frontend"
  value       = aws_s3_bucket.frontend.bucket
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.main.name
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.game_cluster.name
}

output "codepipeline_name" {
  description = "CodePipeline name"
  value       = aws_codepipeline.pipeline.name
}

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "target_group_arn" {
  description = "ALB target group ARN"
  value       = aws_lb_target_group.app.arn
}

output "grafana_dashboard_url" {
  description = "Grafana dashboard URL"
  value       = "${var.grafana_url}/d/${grafana_dashboard.game_monitoring.uid}"
}

output "monitoring_setup" {
  description = "Monitoring setup information"
  value       = "Grafana dashboard created with CloudWatch data source"
}