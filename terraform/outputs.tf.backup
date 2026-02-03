# Primary Region Outputs
output "primary_region" {
  description = "Primary region name"
  value       = var.primary_region
}

output "primary_alb_dns" {
  description = "DNS name of the primary ALB"
  value       = module.primary_alb.alb_dns_name
}

output "primary_alb_arn" {
  description = "ARN of the primary ALB"
  value       = module.primary_alb.alb_arn
}

output "primary_vpc_id" {
  description = "ID of the primary VPC"
  value       = module.primary_vpc.vpc_id
}

output "primary_rds_endpoint" {
  description = "RDS endpoint for primary region"
  value       = module.primary_rds.db_endpoint
  sensitive   = true
}

output "primary_rds_address" {
  description = "RDS address for primary region"
  value       = module.primary_rds.db_address
  sensitive   = true
}

output "primary_s3_bucket" {
  description = "S3 bucket name for static assets (primary)"
  value       = module.primary_s3.bucket_name
}

output "primary_cloudfront_url" {
  description = "CloudFront distribution URL (primary)"
  value       = module.primary_cloudfront.distribution_url
}

# DR Region Outputs
output "dr_region" {
  description = "DR region name"
  value       = var.dr_region
}

output "dr_vpc_id" {
  description = "ID of the DR VPC"
  value       = var.enable_dr ? module.dr_vpc[0].vpc_id : null
}

output "dr_alb_dns" {
  description = "DNS name of the DR ALB (if enabled)"
  value       = var.enable_dr ? module.dr_alb[0].alb_dns_name : null
}

# Common Outputs
output "cloudwatch_alarms" {
  description = "CloudWatch alarm names"
  value       = module.primary_cloudwatch.alarm_names
}

