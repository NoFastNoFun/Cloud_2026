variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN used for IRSA"
  type        = string
}

variable "oidc_issuer_url" {
  description = "OIDC issuer URL from EKS cluster"
  type        = string
}

variable "app_namespace" {
  description = "Application namespace for demo autoscaling resources"
  type        = string
  default     = "online-boutique"
}

variable "enable_cluster_autoscaler" {
  description = "Deploy and configure cluster-autoscaler"
  type        = bool
  default     = true
}

variable "enable_vpa" {
  description = "Deploy VPA controllers and VPA resource"
  type        = bool
  default     = true
}

variable "enable_vpa_resource" {
  description = "Create VerticalPodAutoscaler custom resource (requires VPA CRD already installed)"
  type        = bool
  default     = false
}

variable "enable_hpa_demo" {
  description = "Create demo deployment + HPA in app namespace"
  type        = bool
  default     = true
}

variable "cluster_autoscaler_chart_version" {
  description = "Helm chart version for cluster-autoscaler (empty = latest)"
  type        = string
  default     = ""
}

variable "vpa_chart_version" {
  description = "Helm chart version for VPA (empty = latest)"
  type        = string
  default     = ""
}

variable "hpa_target_deployment_name" {
  description = "Name of the demo deployment used for HPA/VPA"
  type        = string
  default     = "autoscaling-demo"
}
