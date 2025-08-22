resource "aws_codebuild_project" "frontend" {
  name         = "${var.project_name}-frontend-build-${random_string.suffix.result}"
  description  = "Build and deploy frontend for 2048 Game"
  service_role = aws_iam_role.codebuild_role.arn
  
  lifecycle {
    prevent_destroy = false
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "S3_BUCKET"
      value = aws_s3_bucket.frontend.bucket
    }

    environment_variable {
      name  = "API_URL"
      value = "http://${aws_lb.main.dns_name}"
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "13-2048-game-aws-codepipeline/buildspec/frontend-buildspec.yml"
  }

  tags = {
    Name = "${var.project_name}-frontend-build-${random_string.suffix.result}"
  }
}
