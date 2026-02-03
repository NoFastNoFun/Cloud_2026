output "web_acl_id" {
  description = "ID of the WAF Web ACL"
  value       = aws_wafv2_web_acl.cloudfront.id
}

output "web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.cloudfront.arn
}

output "web_acl_capacity" {
  description = "Capacity used by the WAF Web ACL"
  value       = aws_wafv2_web_acl.cloudfront.capacity
}