data "aws_partition" "current" {}

locals {
  cluster_autoscaler_namespace = "kube-system"
  cluster_autoscaler_sa_name   = "cluster-autoscaler"
  oidc_issuer_without_scheme   = replace(var.oidc_issuer_url, "https://", "")
  cluster_autoscaler_chart_ver = var.cluster_autoscaler_chart_version != "" ? var.cluster_autoscaler_chart_version : null
  vpa_chart_ver                = var.vpa_chart_version != "" ? var.vpa_chart_version : null
}

resource "aws_iam_policy" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name = "${var.project_name}-${var.environment}-cluster-autoscaler-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"             = "true",
            "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name = "${var.project_name}-${var.environment}-cluster-autoscaler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_issuer_without_scheme}:aud" = "sts.amazonaws.com",
            "${local.oidc_issuer_without_scheme}:sub" = "system:serviceaccount:${local.cluster_autoscaler_namespace}:${local.cluster_autoscaler_sa_name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  role       = aws_iam_role.cluster_autoscaler[0].name
  policy_arn = aws_iam_policy.cluster_autoscaler[0].arn
}

resource "kubernetes_service_account" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  metadata {
    name      = local.cluster_autoscaler_sa_name
    namespace = local.cluster_autoscaler_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.cluster_autoscaler[0].arn
    }
    labels = {
      "app.kubernetes.io/name" = "cluster-autoscaler"
    }
  }
}

resource "helm_release" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name             = "cluster-autoscaler"
  namespace        = local.cluster_autoscaler_namespace
  repository       = "https://kubernetes.github.io/autoscaler"
  chart            = "cluster-autoscaler"
  version          = local.cluster_autoscaler_chart_ver
  create_namespace = false
  timeout          = 900

  values = [
    yamlencode({
      autoDiscovery = {
        clusterName = var.cluster_name
      }
      awsRegion = var.region
      rbac = {
        serviceAccount = {
          create = false
          name   = local.cluster_autoscaler_sa_name
        }
      }
      extraArgs = {
        "balance-similar-node-groups" = "true"
        "skip-nodes-with-system-pods" = "false"
        "expander"                    = "least-waste"
      }
    })
  ]

  depends_on = [
    aws_iam_role_policy_attachment.cluster_autoscaler,
    kubernetes_service_account.cluster_autoscaler
  ]
}

resource "helm_release" "vpa" {
  count = var.enable_vpa ? 1 : 0

  name             = "vpa"
  namespace        = "kube-system"
  repository       = "https://charts.fairwinds.com/stable"
  chart            = "vpa"
  version          = local.vpa_chart_ver
  create_namespace = false
  timeout          = 900
}

resource "kubernetes_deployment" "autoscaling_demo" {
  count = var.enable_hpa_demo ? 1 : 0

  metadata {
    name      = var.hpa_target_deployment_name
    namespace = var.app_namespace
    labels = {
      app = var.hpa_target_deployment_name
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = var.hpa_target_deployment_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.hpa_target_deployment_name
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:1.27-alpine"

          port {
            container_port = 80
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v2" "autoscaling_demo" {
  count = var.enable_hpa_demo ? 1 : 0

  metadata {
    name      = "${var.hpa_target_deployment_name}-hpa"
    namespace = var.app_namespace
  }

  spec {
    min_replicas = 1
    max_replicas = 10

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.autoscaling_demo[0].metadata[0].name
    }

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 60
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }
  }
}

resource "kubernetes_manifest" "autoscaling_demo_vpa" {
  count = var.enable_vpa_resource && var.enable_hpa_demo ? 1 : 0

  manifest = {
    apiVersion = "autoscaling.k8s.io/v1"
    kind       = "VerticalPodAutoscaler"
    metadata = {
      name      = "${var.hpa_target_deployment_name}-vpa"
      namespace = var.app_namespace
    }
    spec = {
      targetRef = {
        apiVersion = "apps/v1"
        kind       = "Deployment"
        name       = kubernetes_deployment.autoscaling_demo[0].metadata[0].name
      }
      updatePolicy = {
        updateMode = "Auto"
      }
      resourcePolicy = {
        containerPolicies = [
          {
            containerName = "*"
            minAllowed = {
              cpu    = "50m"
              memory = "64Mi"
            }
            maxAllowed = {
              cpu    = "2000m"
              memory = "2Gi"
            }
          }
        ]
      }
    }
  }

  depends_on = [helm_release.vpa, kubernetes_deployment.autoscaling_demo]
}
