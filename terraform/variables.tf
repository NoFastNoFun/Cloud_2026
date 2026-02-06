variable "primary_region" {
  description = "Primary AWS region (Ireland)"
  type        = string
  default     = "eu-west-1"
}

variable "dr_region" {
  description = "Disaster recovery AWS region (Frankfurt)"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment name (e.g., prod, staging)"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "greenleaf"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = []
}

variable "instance_type" {
  description = "EC2 instance type for PrestaShop servers"
  type        = string
  default     = "t3.small"
}

variable "min_size" {
  description = "Minimum number of instances in Auto Scaling Group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in Auto Scaling Group"
  type        = number
  default     = 6
}

variable "desired_capacity" {
  description = "Desired number of instances in Auto Scaling Group"
  type        = number
  default     = 1
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.small"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 50
}

variable "db_engine_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.0"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "prestashop"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "prestashop_admin_email" {
  description = "PrestaShop admin email"
  type        = string
  default     = "admin@greenleaf.example.com"
}

variable "prestashop_admin_password" {
  description = "PrestaShop admin password"
  type        = string
  sensitive   = true
}

variable "prestashop_domain" {
  description = "PrestaShop domain (will be set to ALB DNS if empty)"
  type        = string
  default     = ""
}

variable "enable_dr" {
  description = "Enable disaster recovery region (minimal resources)"
  type        = bool
  default     = false
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "key_pair_name" {
  description = "AWS Key Pair name for EC2 instances"
  type        = string
  default     = ""
}

variable "prestashop_version" {
  description = "PrestaShop version (e.g., 8.* for latest 8.x)"
  type        = string
  default     = "8.*"
}

variable "php_version" {
  description = "PHP version to install"
  type        = string
  default     = "8.2"
}

variable "cloudwatch_alarm_email_endpoints" {
  description = "List of email addresses to receive CloudWatch alarm notifications"
  type        = list(string)
  default     = []
}
