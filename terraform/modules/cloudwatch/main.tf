############################################
# cloudwatch/main.tf 
############################################

# SNS Topic pour les notifications d'alarmes
resource "aws_sns_topic" "cloudwatch_alarms" {
  name = "${var.project_name}-${var.environment}-cloudwatch-alarms"

  tags = {
    Name        = "${var.project_name}-${var.environment}-cloudwatch-alarms"
    Environment = var.environment
  }
}

# SNS Topic Subscription (Email)
resource "aws_sns_topic_subscription" "cloudwatch_alarms_email" {
  count     = length(var.alarm_email_endpoints) > 0 ? length(var.alarm_email_endpoints) : 0
  topic_arn = aws_sns_topic.cloudwatch_alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email_endpoints[count.index]
}

# CloudWatch Alarm - High CPU Utilization
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors EC2 CPU utilization"

  # Actions d'alarme avec SNS topic par défaut
  alarm_actions = length(var.high_cpu_alarm_actions) > 0 ? var.high_cpu_alarm_actions : [aws_sns_topic.cloudwatch_alarms.arn]

  dimensions = {
    AutoScalingGroupName = var.autoscaling_group
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-high-cpu-alarm"
  }
}

# CloudWatch Alarm - Low CPU Utilization
resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 20
  alarm_description   = "This metric monitors EC2 CPU utilization for scale down"

  # Actions d'alarme avec SNS topic par défaut
  alarm_actions = length(var.low_cpu_alarm_actions) > 0 ? var.low_cpu_alarm_actions : [aws_sns_topic.cloudwatch_alarms.arn]

  dimensions = {
    AutoScalingGroupName = var.autoscaling_group
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-low-cpu-alarm"
  }
}

# CloudWatch Alarm - High Memory Utilization
resource "aws_cloudwatch_metric_alarm" "high_memory" {
  alarm_name          = "${var.project_name}-${var.environment}-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2

  # IMPORTANT: aligné avec ton CloudWatch Agent (mem_used_percent)
  metric_name = "mem_used_percent"

  namespace         = "${var.project_name}/${var.environment}"
  period            = 300
  statistic         = "Average"
  threshold         = 85
  alarm_description = "This metric monitors EC2 memory utilization"

  # Actions d'alarme avec SNS topic par défaut
  alarm_actions = length(var.high_memory_alarm_actions) > 0 ? var.high_memory_alarm_actions : [aws_sns_topic.cloudwatch_alarms.arn]

  tags = {
    Name = "${var.project_name}-${var.environment}-high-memory-alarm"
  }
}

# CloudWatch Alarm - RDS High CPU
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

  alarm_actions = length(var.rds_alarm_actions) > 0 ? var.rds_alarm_actions : [aws_sns_topic.cloudwatch_alarms.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-high-cpu-alarm"
  }
}

# CloudWatch Alarm - RDS Free Storage Space
resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-free-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 5000000000
  alarm_description   = "This metric monitors RDS free storage space"

  alarm_actions = length(var.rds_alarm_actions) > 0 ? var.rds_alarm_actions : [aws_sns_topic.cloudwatch_alarms.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-free-storage-alarm"
  }
}

# CloudWatch Alarm - RDS Database Connections
resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 400
  alarm_description   = "This metric monitors RDS database connections"

  alarm_actions = length(var.rds_alarm_actions) > 0 ? var.rds_alarm_actions : [aws_sns_topic.cloudwatch_alarms.arn]

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-connections-alarm"
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "nginx_access" {
  name              = "/aws/ec2/${var.project_name}/${var.environment}/nginx/access"
  retention_in_days = 3

  tags = {
    Name = "${var.project_name}-${var.environment}-nginx-access-logs"
  }
}

resource "aws_cloudwatch_log_group" "nginx_error" {
  name              = "/aws/ec2/${var.project_name}/${var.environment}/nginx/error"
  retention_in_days = 3

  tags = {
    Name = "${var.project_name}-${var.environment}-nginx-error-logs"
  }
}

resource "aws_cloudwatch_log_group" "prestashop_system" {
  name              = "/aws/ec2/${var.project_name}/${var.environment}/prestashop/system"
  retention_in_days = 3

  tags = {
    Name = "${var.project_name}-${var.environment}-prestashop-system-logs"
  }
}

# Ton user-data envoie aussi /var/log/user-data.log, donc il faut le log group correspondant
resource "aws_cloudwatch_log_group" "user_data" {
  name              = "/aws/ec2/${var.project_name}/${var.environment}/user-data"
  retention_in_days = 3

  tags = {
    Name = "${var.project_name}-${var.environment}-user-data-logs"
  }
}

# ============================================================
# ALB CLOUDWATCH ALARMS
# ============================================================

# CloudWatch Alarm - ALB High Response Time
resource "aws_cloudwatch_metric_alarm" "alb_high_response_time" {
  count               = var.alb_target_group_arn != "" ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-alb-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 2
  alarm_description   = "This metric monitors ALB target response time"

  alarm_actions = length(var.alb_alarm_actions) > 0 ? var.alb_alarm_actions : [aws_sns_topic.cloudwatch_alarms.arn]

  dimensions = {
    TargetGroup  = var.alb_target_group_arn
    LoadBalancer = var.alb_arn_suffix
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-high-response-time-alarm"
  }
}

# CloudWatch Alarm - ALB Unhealthy Hosts
resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  count               = var.alb_target_group_arn != "" ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-alb-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "This metric monitors number of unhealthy hosts in target group"

  alarm_actions = length(var.alb_alarm_actions) > 0 ? var.alb_alarm_actions : [aws_sns_topic.cloudwatch_alarms.arn]

  dimensions = {
    TargetGroup  = var.alb_target_group_arn
    LoadBalancer = var.alb_arn_suffix
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-unhealthy-hosts-alarm"
  }
}

# CloudWatch Alarm - ALB 5XX Errors
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  count               = var.alb_arn_suffix != "" ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "This metric monitors ALB 5XX errors"

  alarm_actions = length(var.alb_alarm_actions) > 0 ? var.alb_alarm_actions : [aws_sns_topic.cloudwatch_alarms.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-5xx-errors-alarm"
  }
}

# ============================================================
# CLOUDWATCH DASHBOARD
# ============================================================

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average", label = "EC2 CPU Average" }],
            ["${var.project_name}/${var.environment}", "mem_used_percent", { stat = "Average", label = "Memory Used %" }]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "EC2 - CPU & Memory"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", { stat = "Average", label = "RDS CPU", dimensions = { DBInstanceIdentifier = var.rds_instance_id } }],
            [".", "DatabaseConnections", { stat = "Average", label = "DB Connections", dimensions = { DBInstanceIdentifier = var.rds_instance_id } }]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "RDS - Performance Metrics"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", { stat = "Average", label = "Free Storage", dimensions = { DBInstanceIdentifier = var.rds_instance_id } }]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "RDS - Storage"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", { stat = "Average", label = "Response Time" }],
            [".", "RequestCount", { stat = "Sum", label = "Request Count" }]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "ALB - Performance"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", { stat = "Average", label = "Healthy Hosts" }],
            [".", "UnHealthyHostCount", { stat = "Average", label = "Unhealthy Hosts" }]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "ALB - Target Health"
        }
      },
      {
        type = "log"
        properties = {
          query  = "SOURCE '/aws/ec2/${var.project_name}/${var.environment}/nginx/error' | fields @timestamp, @message | sort @timestamp desc | limit 20"
          region = var.region
          title  = "Recent Nginx Errors"
        }
      }
    ]
  })
}
