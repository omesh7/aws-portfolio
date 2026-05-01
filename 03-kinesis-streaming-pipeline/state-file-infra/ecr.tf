resource "aws_ecr_repository" "producer_app" {
  name = "${var.project_name}-repository"
  image_scanning_configuration {
    scan_on_push = true
  }
  image_tag_mutability = "MUTABLE"
  force_delete         = true

}


output "ecr_repo_uri" {
  value = aws_ecr_repository.producer_app.repository_url
}
