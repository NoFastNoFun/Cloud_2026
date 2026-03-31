variable "project_name" { type = string }
variable "environment" { type = string }
variable "alb_arn" { type = string }
variable "rate_limit_per_ip" {
  type    = number
  default = 2000
}
