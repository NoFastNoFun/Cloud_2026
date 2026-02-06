output "alarm_names" {
  description = "Names of all CloudWatch alarms"
  value = concat(
    [
      aws_cloudwatch_metric_alarm.high_cpu.alarm_name,
      aws_cloudwatch_metric_alarm.low_cpu.alarm_name,
      aws_cloudwatch_metric_alarm.high_memory.alarm_name,
      aws_cloudwatch_metric_alarm.rds_high_cpu.alarm_name,
      aws_cloudwatch_metric_alarm.rds_free_storage.alarm_name,
      aws_cloudwatch_metric_alarm.rds_connections.alarm_name
    ],
    aws_cloudwatch_metric_alarm.alb_high_response_time[*].alarm_name,
    aws_cloudwatch_metric_alarm.alb_unhealthy_hosts[*].alarm_name,
    aws_cloudwatch_metric_alarm.alb_5xx_errors[*].alarm_name
  )
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for CloudWatch alarms"
  value       = aws_sns_topic.cloudwatch_alarms.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic for CloudWatch alarms"
  value       = aws_sns_topic.cloudwatch_alarms.name
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "log_group_names" {
  description = "Names of all CloudWatch log groups"
  value = {
    nginx_access      = aws_cloudwatch_log_group.nginx_access.name
    nginx_error       = aws_cloudwatch_log_group.nginx_error.name
    prestashop_system = aws_cloudwatch_log_group.prestashop_system.name
    user_data         = aws_cloudwatch_log_group.user_data.name
  }
}

