# Application Load Balancer
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name    = "${var.project_name}-${var.environment}-alb"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"

      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = aws_acm_certificate.alb.arn

      forward = {
        target_group_key = "backend"
      }
    }
  }

  target_groups = {
    backend = {
      name                 = "${var.project_name}-${var.environment}-backend"
      protocol             = "HTTP"
      port                 = var.backend_container_port
      target_type          = "ip"
      deregistration_delay = 30

      health_check = {
        enabled             = true
        interval            = 30
        path                = "/health"
        port                = "traffic-port"
        healthy_threshold   = 2
        unhealthy_threshold = 3
        timeout             = 5
        protocol            = "HTTP"
        matcher             = "200"
      }

      create_attachment = false
    }
  }

  depends_on = [aws_acm_certificate_validation.alb]

  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cluster"
  }
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs_backend" {
  name              = "/ecs/${var.project_name}-${var.environment}/backend"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-backend-logs"
  }
}

resource "aws_cloudwatch_log_group" "ecs_adot" {
  name              = "/ecs/${var.project_name}-${var.environment}/adot"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-adot-logs"
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-${var.environment}-ecs-task-execution-role"

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

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-task-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional policy for accessing Secrets Manager
resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  name = "${var.project_name}-${var.environment}-ecs-secrets-policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.db_connection.arn
        ]
      }
    ]
  })
}

# IAM Role for ECS Task
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-${var.environment}-ecs-task-role"

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

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-task-role"
  }
}

# Policy for ADOT Collector - CloudWatch and X-Ray
resource "aws_iam_role_policy" "ecs_task_adot" {
  name = "${var.project_name}-${var.environment}-ecs-adot-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups",
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets",
          "xray:GetSamplingStatisticSummaries",
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "ssm:GetParameters"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy for ECS Exec (SSM Session Manager)
resource "aws_iam_role_policy" "ecs_task_exec_policy" {
  name = "${var.project_name}-${var.environment}-ecs-exec-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}

# Application Signals Policy
resource "aws_iam_role_policy_attachment" "ecs_task_application_signals" {
  count      = var.enable_application_signals ? 1 : 0
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchApplicationSignalsFullAccess"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-${var.environment}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.backend_cpu
  memory                   = var.backend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "backend"
      image = "${aws_ecr_repository.backend.repository_url}:latest"
      
      portMappings = [
        {
          containerPort = var.backend_container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "NODE_ENV"
          value = var.environment
        },
        {
          name  = "PORT"
          value = tostring(var.backend_container_port)
        },
        {
          name  = "OTEL_SERVICE_NAME"
          value = "${var.project_name}-backend"
        },
        {
          name  = "OTEL_EXPORTER_OTLP_ENDPOINT"
          value = "http://localhost:4318"
        },
        {
          name  = "OTEL_TRACES_SAMPLER"
          value = "always_on"
        }
      ]

      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = "${aws_secretsmanager_secret.db_connection.arn}:database_url::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_backend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "backend"
        }
      }

      dependsOn = [
        {
          containerName = "adot-collector"
          condition     = "START"
        }
      ]
    },
    {
      name      = "adot-collector"
      image     = "public.ecr.aws/aws-observability/aws-otel-collector:latest"
      essential = true

      command = ["--config=env:ADOT_CONFIG_CONTENT"]

      environment = [
        {
          name  = "DEPLOYMENT_ENVIRONMENT"
          value = var.environment
        },
        {
          name  = "OTEL_SERVICE_NAME"
          value = "${var.project_name}-backend"
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "ADOT_CONFIG_CONTENT"
          value = file("${path.module}/adot-collector-config/adot-config.yaml")
        }
      ]

      portMappings = [
        {
          containerPort = 4318
          protocol      = "tcp"
        },
        {
          containerPort = 4317
          protocol      = "tcp"
        },
        {
          containerPort = 2000
          protocol      = "udp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_adot.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "adot"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-${var.environment}-backend-task"
  }
}

# ECS Service
resource "aws_ecs_service" "backend" {
  name            = "${var.project_name}-${var.environment}-backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = var.backend_desired_count
  launch_type     = "FARGATE"

  # Enable ECS Exec for debugging and migrations
  enable_execute_command = true

  # Health check grace period for application startup
  health_check_grace_period_seconds = 60

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = module.alb.target_groups["backend"].arn
    container_name   = "backend"
    container_port   = var.backend_container_port
  }

  # Enable Application Auto Scaling
  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [module.alb]

  tags = {
    Name = "${var.project_name}-${var.environment}-backend-service"
  }
}

# Auto Scaling Target
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.backend.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Auto Scaling Policy - CPU
resource "aws_appautoscaling_policy" "ecs_cpu" {
  name               = "${var.project_name}-${var.environment}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# Auto Scaling Policy - Memory
resource "aws_appautoscaling_policy" "ecs_memory" {
  name               = "${var.project_name}-${var.environment}-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 80.0
  }
}
