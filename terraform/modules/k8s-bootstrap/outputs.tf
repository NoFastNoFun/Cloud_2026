output "app_namespace" {
  description = "Application namespace"
  value       = kubernetes_namespace.app.metadata[0].name
}

output "observability_namespace" {
  description = "Observability namespace"
  value       = kubernetes_namespace.observability.metadata[0].name
}

output "deployer_service_account" {
  description = "Service account for deployment automation"
  value       = kubernetes_service_account.deployer.metadata[0].name
}

output "metrics_server_release_name" {
  description = "Helm release name for metrics-server"
  value       = var.enable_metrics_server ? helm_release.metrics_server[0].name : null
}
