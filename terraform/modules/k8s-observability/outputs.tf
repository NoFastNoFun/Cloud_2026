output "observability_namespace" {
  description = "Namespace used for observability stack"
  value       = var.observability_namespace
}

output "prometheus_stack_release_name" {
  description = "Helm release name for kube-prometheus-stack"
  value       = var.enable_prometheus_stack ? helm_release.kube_prometheus_stack[0].name : null
}

output "jaeger_release_name" {
  description = "Helm release name for Jaeger"
  value       = var.enable_jaeger ? helm_release.jaeger[0].name : null
}
