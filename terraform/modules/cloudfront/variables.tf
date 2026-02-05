variable "s3_bucket_domain" {
  description = "Domain name of the S3 bucket"
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

variable "web_acl_id" {
  description = "ID of the WAFv2 Web ACL for CloudFront"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer (ALB)"
  type        = string
}


