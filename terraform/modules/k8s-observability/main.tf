locals {
  prometheus_chart_ver = var.prometheus_stack_chart_version != "" ? var.prometheus_stack_chart_version : null
  jaeger_chart_ver     = var.jaeger_chart_version != "" ? var.jaeger_chart_version : null
}

resource "helm_release" "kube_prometheus_stack" {
  count = var.enable_prometheus_stack ? 1 : 0

  name             = "kube-prometheus-stack"
  namespace        = var.observability_namespace
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = local.prometheus_chart_ver
  create_namespace = true
  timeout          = 1200

  values = [
    yamlencode({
      grafana = {
        service = {
          type = "ClusterIP"
        }
      }
      prometheus = {
        prometheusSpec = {
          retention = var.prometheus_retention
        }
      }
      alertmanager = {
        enabled = true
      }
    })
  ]

  dynamic "set_sensitive" {
    for_each = var.grafana_admin_password != "" ? [1] : []
    content {
      name  = "grafana.adminPassword"
      value = var.grafana_admin_password
    }
  }
}

resource "helm_release" "jaeger" {
  count = var.enable_jaeger ? 1 : 0

  name             = "jaeger"
  namespace        = var.observability_namespace
  repository       = "https://jaegertracing.github.io/helm-charts"
  chart            = "jaeger"
  version          = local.jaeger_chart_ver
  create_namespace = true
  timeout          = 900

  values = [
    yamlencode({
      provisionDataStore = {
        cassandra = false
      }
      allInOne = {
        enabled = true
      }
      storage = {
        type = "memory"
      }
    })
  ]
}
