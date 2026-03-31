variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "rate_limit_per_ip" {
  description = "WAF rate limit per IP on a 5-minute window"
  type        = number
  default     = 2000
}
