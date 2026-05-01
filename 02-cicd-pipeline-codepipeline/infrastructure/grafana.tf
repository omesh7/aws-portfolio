resource "grafana_data_source" "cloudwatch" {
  type = "cloudwatch"
  name = "AWS CloudWatch ${random_string.suffix.result}"
  url  = "https://monitoring.${var.aws_region}.amazonaws.com"

  json_data_encoded = jsonencode({
    defaultRegion = var.aws_region
    authType      = "arn"
    assumeRoleArn = var.aws_role_arn
  })
}

# Simple dashboard for 2048 game monitoring
resource "grafana_dashboard" "game_monitoring" {
  config_json = jsonencode({
    title = "2048 Game Monitoring ${random_string.suffix.result}"
    panels = [
      {
        id    = 1
        title = "ALB Request Count"
        type  = "stat"
        targets = [{
          datasource = grafana_data_source.cloudwatch.name
          namespace  = "AWS/ApplicationELB"
          metricName = "RequestCount"
          dimensions = {
            LoadBalancer = aws_lb.main.arn_suffix
          }
        }]
        gridPos = { h = 8, w = 12, x = 0, y = 0 }
      },
      {
        id    = 2
        title = "ECS CPU Usage"
        type  = "timeseries"
        targets = [{
          datasource = grafana_data_source.cloudwatch.name
          namespace  = "AWS/ECS"
          metricName = "CPUUtilization"
          dimensions = {
            ServiceName = aws_ecs_service.main.name
            ClusterName = aws_ecs_cluster.game_cluster.name
          }
        }]
        gridPos = { h = 8, w = 12, x = 12, y = 0 }
      }
    ]
  })
}

# CloudWatch Log Stream for real-time monitoring
resource "aws_cloudwatch_log_stream" "ecs_stream" {
  name           = "ecs-stream-${random_string.suffix.result}"
  log_group_name = aws_cloudwatch_log_group.ecs.name
}

# Enhanced dashboard with real-time streaming
resource "grafana_dashboard" "realtime_monitoring" {
  config_json = jsonencode({
    title = "Real-time 2048 Game Monitoring ${random_string.suffix.result}"
    refresh = "5s"
    panels = [
      {
        id = 3
        title = "Live Request Rate"
        type = "timeseries"
        targets = [{
          datasource = grafana_data_source.cloudwatch.name
          namespace = "AWS/ApplicationELB"
          metricName = "RequestCount"
          statistic = "Sum"
          period = "60"
          dimensions = {
            LoadBalancer = aws_lb.main.arn_suffix
          }
        }]
        gridPos = { h = 8, w = 24, x = 0, y = 8 }
      },
      {
        id = 4
        title = "Live ECS Logs"
        type = "logs"
        targets = [{
          datasource = grafana_data_source.cloudwatch.name
          logGroups = [aws_cloudwatch_log_group.ecs.name]
          region = var.aws_region
        }]
        gridPos = { h = 12, w = 24, x = 0, y = 16 }
      }
    ]
  })
}

# CloudWatch alarms
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu-${random_string.suffix.result}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "High CPU usage alert"

  dimensions = {
    ServiceName = aws_ecs_service.main.name
    ClusterName = aws_ecs_cluster.game_cluster.name
  }
}