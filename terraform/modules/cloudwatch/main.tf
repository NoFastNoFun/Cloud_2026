############################################
# cloudwatch/main.tf (modifié)
############################################

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

  # Optionnel: brancher une action (SNS ou scaling policy) via var.high_cpu_alarm_actions
  alarm_actions = var.high_cpu_alarm_actions

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

  # Optionnel: brancher une action (SNS ou scaling policy) via var.low_cpu_alarm_actions
  alarm_actions = var.low_cpu_alarm_actions

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

  # Optionnel: brancher une action via var.high_memory_alarm_actions
  alarm_actions = var.high_memory_alarm_actions

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

  alarm_actions = var.rds_alarm_actions

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

  alarm_actions = var.rds_alarm_actions

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

  alarm_actions = var.rds_alarm_actions

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
