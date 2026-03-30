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
}

data "aws_eks_cluster" "primary" {
  count = var.enable_k8s_bootstrap ? 1 : 0
  name  = local.effective_eks_cluster_name
}

data "aws_eks_cluster_auth" "primary" {
  count = var.enable_k8s_bootstrap ? 1 : 0
  name  = local.effective_eks_cluster_name
}

provider "kubernetes" {
  alias                  = "eks"
  host                   = var.enable_k8s_bootstrap ? data.aws_eks_cluster.primary[0].endpoint : null
  cluster_ca_certificate = var.enable_k8s_bootstrap ? base64decode(data.aws_eks_cluster.primary[0].certificate_authority[0].data) : null
  token                  = var.enable_k8s_bootstrap ? data.aws_eks_cluster_auth.primary[0].token : null
}

provider "helm" {
  alias = "eks"

  kubernetes {
    host                   = var.enable_k8s_bootstrap ? data.aws_eks_cluster.primary[0].endpoint : null
    cluster_ca_certificate = var.enable_k8s_bootstrap ? base64decode(data.aws_eks_cluster.primary[0].certificate_authority[0].data) : null
    token                  = var.enable_k8s_bootstrap ? data.aws_eks_cluster_auth.primary[0].token : null
  }
}
