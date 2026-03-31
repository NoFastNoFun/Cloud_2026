variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "allowlist_ipv4_cidrs" {
  description = "IPv4 CIDRs to bypass WAF rules (example: [\"203.0.113.10/32\"])"
  type        = list(string)
  default     = []
}
