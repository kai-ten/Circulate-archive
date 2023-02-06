resource "aws_cloudwatch_log_group" "circulate_ecs_log_group" {
  name = "/aws/ecs/${var.service}-log-group"
  retention_in_days = 7
}

resource "aws_iam_role" "circulate_ecs_task_exec_role" {
  name_prefix = "${var.service}-task-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name = "Policy"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Action = [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          Effect = "Allow",
          Resource = "${aws_cloudwatch_log_group.circulate_ecs_log_group.arn}:*"
        },
        {
          Action = [
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage"
          ],
          Effect = "Allow",
          Resource = "${aws_ecr_repository.dbt_postgres_ecr_repo.arn}"
        }
      ]
    })
  }
}

resource "aws_iam_role" "circulate_ecs_task_role" {
  name = "${var.service}-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name = "EFSPolicy"
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Action = [
            "elasticfilesystem:ClientMount",
            "elasticfilesystem:ClientWrite"
          ],
          Effect = "Allow",
          Resource = "${var.efs_arn}"
        }
      ]
    })
  }
}

resource "aws_ecs_task_definition" "task" {
  family                = "${var.service}-${var.env}-task"
  # container_definitions = file("task-definitions/service.json")
  container_definitions = jsonencode([
    {
      "command": [
        "/bin/sh -c \"pwd && ls /usr/app && mkdir -p /root/.dbt && cp /usr/app/profiles.yml /root/.dbt/profiles.yml && dbt run\""
      ],
      "entryPoint": [
        "sh",
        "-c"
      ],
      "name": "${var.service}-${var.env}-task",
      "image": "${aws_ecr_repository.dbt_postgres_ecr_repo.repository_url}:latest",
      "portMappings": [
        {
          "name": "rds",
          "protocol": "tcp",
          "containerPort": 5432,
          "hostPort": 5432
        }
      ],
      "cpu": 2048,
      "memory": 4096,
      "environment": [{ "name": "myvariable", "value": "myvalue" }],
      "healthCheck": {
        "command": [ "CMD-SHELL", "curl -f http://localhost/ || exit 1" ], 
        "interval": 30,
        "retries": 3,
        "startPeriod": 120,
        "timeout": 5
      },
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/aws/ecs/${var.service}-log-group",
          "awslogs-region": "${data.aws_region.current.name}",
          "awslogs-create-group": "true",
          "awslogs-stream-prefix": "dbt"
        }
      },
      "mountPoints": [{
        "containerPath": "/usr/app", 
        "readOnly": false,
        "sourceVolume": "dbt-config"
      }]
    }
  ])
  cpu = 2048 #var.task_definition.cpu
  memory = 4096 #var.task_definition.memory
  network_mode = "awsvpc"
  execution_role_arn = aws_iam_role.circulate_ecs_task_exec_role.arn
  task_role_arn = aws_iam_role.circulate_ecs_task_role.arn
  requires_compatibilities = ["FARGATE"]

  

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture = "X86_64"
  }

  volume {
    name = "dbt-config" #var.task_definition.volume_name

    efs_volume_configuration {
      file_system_id          = var.efs_id
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2999
      authorization_config {
        access_point_id = aws_efs_access_point.dbt_ap.id
        iam             = "ENABLED" // iam role must have perms to mount filesystem
      }
    }
  }
}
