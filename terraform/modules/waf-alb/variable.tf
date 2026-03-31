variable "project_name" { type = string }
variable "environment" { type = string }
variable "alb_arn" { type = string }

variable "allowlist_ipv4_cidrs" {
  description = "IPv4 CIDRs to bypass ALB WAF rules (example: [\"203.0.113.10/32\"])"
  type        = list(string)
  default     = []
}
