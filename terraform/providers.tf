terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14"
    }
  }
}

provider "aws" {
  region = var.primary_region

  default_tags {
    tags = {
      Project     = "GreenLeaf"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "GreenLeaf"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Layer       = "Global-Security"
    }
  }
}

provider "aws" {
  alias  = "dr"
  region = var.dr_region

  default_tags {
    tags = {
      Project     = "GreenLeaf"
      Environment = "${var.environment}-dr"
      ManagedBy   = "Terraform"
    }
  }
}

locals {
  effective_eks_cluster_name = var.eks_cluster_name != "" ? var.eks_cluster_name : "${var.project_name}-${var.environment}-eks"
  enable_k8s_providers       = var.enable_k8s_bootstrap || var.enable_k8s_autoscaling || var.enable_k8s_observability
}

data "aws_eks_cluster" "primary" {
  count = local.enable_k8s_providers ? 1 : 0
  name  = local.effective_eks_cluster_name
}

provider "kubernetes" {
  alias                  = "eks"
  host                   = local.enable_k8s_providers ? data.aws_eks_cluster.primary[0].endpoint : null
  cluster_ca_certificate = local.enable_k8s_providers ? base64decode(data.aws_eks_cluster.primary[0].certificate_authority[0].data) : null

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--region",
      var.primary_region,
      "--cluster-name",
      local.effective_eks_cluster_name,
    ]
  }
}

provider "helm" {
  alias = "eks"

  kubernetes {
    host                   = local.enable_k8s_providers ? data.aws_eks_cluster.primary[0].endpoint : null
    cluster_ca_certificate = local.enable_k8s_providers ? base64decode(data.aws_eks_cluster.primary[0].certificate_authority[0].data) : null

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--region",
        var.primary_region,
        "--cluster-name",
        local.effective_eks_cluster_name,
      ]
    }
  }
}
