variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "autoscaling_group" {
  description = "Name of the Auto Scaling Group"
  type        = string
}

variable "rds_instance_id" {
  description = "ID of the RDS instance"
  type        = string
}

variable "alb_target_group_arn" {
  description = "ARN of the ALB target group (full ARN)"
  type        = string
  default     = ""
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB (format: app/name/id)"
  type        = string
  default     = ""
}

variable "alarm_email_endpoints" {
  type        = list(string)
  description = "List of email addresses to receive alarm notifications"
  default     = []
}

variable "high_cpu_alarm_actions" {
  type        = list(string)
  description = "Actions for high CPU alarm (SNS topic ARN, scaling policy ARN, etc.)"
  default     = []
}

variable "low_cpu_alarm_actions" {
  type        = list(string)
  description = "Actions for low CPU alarm (SNS topic ARN, scaling policy ARN, etc.)"
  default     = []
}

variable "high_memory_alarm_actions" {
  type        = list(string)
  description = "Actions for high memory alarm (SNS topic ARN, etc.)"
  default     = []
}

variable "rds_alarm_actions" {
  type        = list(string)
  description = "Actions for RDS alarms (SNS topic ARN, etc.)"
  default     = []
}

variable "alb_alarm_actions" {
  type        = list(string)
  description = "Actions for ALB alarms (SNS topic ARN, etc.)"
  default     = []
}
