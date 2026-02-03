variable "s3_bucket_domain" {
  description = "Domain name of the S3 bucket"
  type        = string
}

variable "alb_domain_name" {
  description = "Domain name of the ALB for CloudFront origin"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "waf_acl_id" {
  description = "WAF Web ACL ID to associate with CloudFront"
  type        = string
  default     = ""  # Optionnel si pas encore de WAF
}