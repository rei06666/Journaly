# CloudWatch Dashboard for Application Monitoring
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", { stat = "Average" }],
            [".", "MemoryUtilization", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ECS Resource Utilization"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", { stat = "Average" }],
            [".", "RequestCount", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ALB Metrics"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", { stat = "Average" }],
            [".", "DatabaseConnections", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS Metrics"
        }
      }
    ]
  })
}

# CloudWatch Alarms - ECS High CPU
resource "aws_cloudwatch_metric_alarm" "ecs_high_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-ecs-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors ECS CPU utilization"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.backend.name
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-high-cpu"
  }
}

# CloudWatch Alarms - ECS High Memory
resource "aws_cloudwatch_metric_alarm" "ecs_high_memory" {
  alarm_name          = "${var.project_name}-${var.environment}-ecs-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors ECS memory utilization"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.backend.name
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ecs-high-memory"
  }
}

# CloudWatch Alarms - ALB Unhealthy Target
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_target" {
  alarm_name          = "${var.project_name}-${var.environment}-alb-unhealthy-target"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Alert when ALB has unhealthy targets"

  dimensions = {
    LoadBalancer = module.alb.arn_suffix
    TargetGroup  = module.alb.target_groups["backend"].arn_suffix
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-unhealthy-target"
  }
}

# CloudWatch Alarms - RDS High CPU
resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors RDS CPU utilization"

  dimensions = {
    DBInstanceIdentifier = module.rds.db_instance_identifier
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-high-cpu"
  }
}

# CloudWatch Log Insights Query Definitions
resource "aws_cloudwatch_query_definition" "error_logs" {
  name = "${var.project_name}-${var.environment}-error-logs"

  log_group_names = [
    aws_cloudwatch_log_group.ecs_backend.name
  ]

  query_string = <<-QUERY
    fields @timestamp, @message
    | filter @message like /ERROR/
    | sort @timestamp desc
    | limit 100
  QUERY
}

resource "aws_cloudwatch_query_definition" "slow_requests" {
  name = "${var.project_name}-${var.environment}-slow-requests"

  log_group_names = [
    aws_cloudwatch_log_group.ecs_backend.name
  ]

  query_string = <<-QUERY
    fields @timestamp, @message
    | filter @message like /duration/
    | parse @message /duration: (?<duration>\d+)/
    | filter duration > 1000
    | sort duration desc
    | limit 100
  QUERY
}

# SNS Topic for Alarms (Optional)
resource "aws_sns_topic" "alarms" {
  name = "${var.project_name}-${var.environment}-alarms"

  tags = {
    Name = "${var.project_name}-${var.environment}-alarms"
  }
}

# Subscribe alarms to SNS topic (uncomment when you have email to subscribe)
# resource "aws_sns_topic_subscription" "alarm_email" {
#   topic_arn = aws_sns_topic.alarms.arn
#   protocol  = "email"
#   endpoint  = "your-email@example.com"
# }
