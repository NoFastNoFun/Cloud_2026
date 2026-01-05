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
  description = "EC2 instance type for Magento servers"
  type        = string
  default     = "t3.medium"
}

variable "min_size" {
  description = "Minimum number of instances in Auto Scaling Group"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances in Auto Scaling Group"
  type        = number
  default     = 6
}

variable "desired_capacity" {
  description = "Desired number of instances in Auto Scaling Group"
  type        = number
  default     = 2
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 100
}

variable "db_engine_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.0"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "magento"
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

variable "magento_admin_username" {
  description = "Magento admin username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "magento_admin_password" {
  description = "Magento admin password"
  type        = string
  sensitive   = true
}

variable "magento_admin_email" {
  description = "Magento admin email"
  type        = string
  default     = "admin@greenleaf.example.com"
}

variable "magento_base_url" {
  description = "Magento base URL"
  type        = string
  default     = ""
}

variable "enable_dr" {
  description = "Enable disaster recovery region (minimal resources)"
  type        = bool
  default     = true
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

variable "magento_version" {
  description = "Magento Open Source version"
  type        = string
  default     = "2.4.7"
}

variable "php_version" {
  description = "PHP version to install"
  type        = string
  default     = "8.2"
}

