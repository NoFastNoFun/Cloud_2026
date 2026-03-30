variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "app_namespace" {
  description = "Namespace for application workloads"
  type        = string
  default     = "online-boutique"
}

variable "observability_namespace" {
  description = "Namespace for observability workloads"
  type        = string
  default     = "observability"
}

variable "enable_metrics_server" {
  description = "Deploy metrics-server via Helm"
  type        = bool
  default     = true
}

variable "metrics_server_chart_version" {
  description = "Metrics-server chart version"
  type        = string
  default     = "3.12.2"
}
