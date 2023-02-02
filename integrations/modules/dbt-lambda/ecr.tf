resource "aws_ecr_repository" "dbt_postgres_ecr_repo" {
  name                 = "${var.name}-${var.env}-${var.service}-repo"
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

  provisioner "local-exec" {
    command = <<-EOT
docker image pull ghcr.io/dbt-labs/dbt-postgres:1.2.3

aws ecr get-login-password \
    --region ${data.aws_region.current.name} \
| docker login \
    --username AWS \
    --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com

docker tag ghcr.io/dbt-labs/dbt-postgres:latest ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${aws_ecr_repository.dbt_postgres_ecr_repo.name}

docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${aws_ecr_repository.dbt_postgres_ecr_repo.name}
    EOT
  }
}
