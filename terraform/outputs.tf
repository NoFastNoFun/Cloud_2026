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

output "cloudwatch_sns_topic" {
  description = "SNS topic ARN for CloudWatch alarms"
  value       = module.primary_cloudwatch.sns_topic_arn
}

output "cloudwatch_dashboard" {
  description = "CloudWatch dashboard name"
  value       = module.primary_cloudwatch.dashboard_name
}

output "cloudwatch_log_groups" {
  description = "CloudWatch log group names"
  value       = module.primary_cloudwatch.log_group_names
}

output "dr_cloudwatch_alarms" {
  description = "DR CloudWatch alarm names"
  value       = var.enable_dr ? module.dr_cloudwatch[0].alarm_names : null
}

output "dr_cloudwatch_dashboard" {
  description = "DR CloudWatch dashboard name"
  value       = var.enable_dr ? module.dr_cloudwatch[0].dashboard_name : null
}

output "primary_eks_cluster_name" {
  description = "Primary EKS cluster name (if enabled)"
  value       = var.enable_eks ? module.primary_eks[0].cluster_name : null
}

output "primary_eks_cluster_arn" {
  description = "Primary EKS cluster ARN (if enabled)"
  value       = var.enable_eks ? module.primary_eks[0].cluster_arn : null
}

output "primary_eks_cluster_endpoint" {
  description = "Primary EKS cluster endpoint (if enabled)"
  value       = var.enable_eks ? module.primary_eks[0].cluster_endpoint : null
}

output "primary_eks_node_group_name" {
  description = "Primary EKS node group name (if enabled)"
  value       = var.enable_eks ? module.primary_eks[0].node_group_name : null
}

output "primary_eks_oidc_provider_arn" {
  description = "Primary EKS OIDC provider ARN for IRSA (if enabled)"
  value       = var.enable_eks ? module.primary_eks[0].oidc_provider_arn : null
}

output "k8s_app_namespace" {
  description = "Kubernetes application namespace created by bootstrap module"
  value       = var.enable_k8s_bootstrap ? module.k8s_bootstrap[0].app_namespace : null
}

output "k8s_observability_namespace" {
  description = "Kubernetes observability namespace created by bootstrap module"
  value       = var.enable_k8s_bootstrap ? module.k8s_bootstrap[0].observability_namespace : null
}

output "k8s_deployer_service_account" {
  description = "Kubernetes deployer service account name"
  value       = var.enable_k8s_bootstrap ? module.k8s_bootstrap[0].deployer_service_account : null
}

output "k8s_metrics_server_release_name" {
  description = "Helm release name for metrics-server"
  value       = var.enable_k8s_bootstrap ? module.k8s_bootstrap[0].metrics_server_release_name : null
}

