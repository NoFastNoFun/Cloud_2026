output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.magento.name
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.magento.arn
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.magento.id
}

