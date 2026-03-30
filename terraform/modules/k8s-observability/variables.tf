variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "observability_namespace" {
  description = "Namespace where observability stack is deployed"
  type        = string
  default     = "observability"
}

variable "enable_prometheus_stack" {
  description = "Deploy kube-prometheus-stack (Prometheus + Grafana + Alertmanager)"
  type        = bool
  default     = true
}

variable "enable_jaeger" {
  description = "Deploy Jaeger tracing stack"
  type        = bool
  default     = true
}

variable "prometheus_stack_chart_version" {
  description = "Helm chart version for kube-prometheus-stack (empty = latest)"
  type        = string
  default     = ""
}

variable "jaeger_chart_version" {
  description = "Helm chart version for Jaeger (empty = latest)"
  type        = string
  default     = ""
}

variable "prometheus_retention" {
  description = "Prometheus retention period"
  type        = string
  default     = "7d"
}

variable "grafana_admin_password" {
  description = "Grafana admin password (empty = chart default secret)"
  type        = string
  default     = ""
  sensitive   = true
}
