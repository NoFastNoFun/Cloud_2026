output "cluster_autoscaler_iam_role_arn" {
  description = "IAM role ARN used by cluster-autoscaler"
  value       = var.enable_cluster_autoscaler ? aws_iam_role.cluster_autoscaler[0].arn : null
}

output "cluster_autoscaler_release_name" {
  description = "Helm release name of cluster-autoscaler"
  value       = var.enable_cluster_autoscaler ? helm_release.cluster_autoscaler[0].name : null
}

output "vpa_release_name" {
  description = "Helm release name of VPA controllers"
  value       = var.enable_vpa ? helm_release.vpa[0].name : null
}

output "hpa_name" {
  description = "Name of demo HPA"
  value       = var.enable_hpa_demo ? kubernetes_horizontal_pod_autoscaler_v2.autoscaling_demo[0].metadata[0].name : null
}

output "vpa_name" {
  description = "Name of demo VPA resource"
  value       = var.enable_vpa_resource && var.enable_hpa_demo ? kubernetes_manifest.autoscaling_demo_vpa[0].manifest["metadata"]["name"] : null
}
