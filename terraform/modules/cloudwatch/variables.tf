variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "autoscaling_group" {
  description = "Name of the Auto Scaling Group"
  type        = string
}

variable "rds_instance_id" {
  description = "ID of the RDS instance"
  type        = string
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