variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "IDs of the public subnets (for Ansible access)"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID of the EC2 security group"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the target group"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
}

variable "desired_capacity" {
  description = "Desired number of instances"
  type        = number
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "key_pair_name" {
  description = "AWS Key Pair name"
  type        = string
  default     = ""
}

variable "db_endpoint" {
  description = "RDS endpoint"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "s3_bucket_name" {
  description = "S3 bucket name for static assets"
  type        = string
}

variable "cloudfront_url" {
  description = "CloudFront distribution URL"
  type        = string
}

variable "prestashop_version" {
  description = "PrestaShop version"
  type        = string
}

variable "php_version" {
  description = "PHP version"
  type        = string
}

variable "prestashop_admin_email" {
  description = "PrestaShop admin email"
  type        = string
}

variable "prestashop_admin_password" {
  description = "PrestaShop admin password"
  type        = string
  sensitive   = true
}

variable "prestashop_domain" {
  description = "PrestaShop domain"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

