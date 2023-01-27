data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Pulls the image
resource "docker_image" "dbt_postgres_image" {
  name = "ghcr.io/dbt-labs/dbt-postgres:latest"
}

# Create a container
resource "docker_container" "dbt_postgres_container" {
  image = docker_image.dbt_postgres_image.image_id
  name  = "${var.name}-${var.env}-${var.image}"
}

resource "aws_ecr_repository" "dbt_postgres_ecr_repo" {
  name                 = "${var.name}-${var.env}-${var.image}-repo"
  image_tag_mutability = "IMMUTABLE"
}

resource "aws_ecr_repository_policy" "dbt_postgres_ecr_repo_policy" {
  repository = aws_ecr_repository.dbt_postgres_ecr_repo.name
  policy     = <<EOF
  {
    "Version": "2008-10-17",
    "Statement": [
      {
        "Sid": "Set the permission for ECR",
        "Effect": "Allow",
        "Principal": "*",
        "Action": [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetLifecyclePolicy",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
      }
    ]
  }
  EOF
}
