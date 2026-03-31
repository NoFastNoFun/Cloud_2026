data "aws_availability_zones" "primary" {
  state = "available"
}

data "aws_availability_zones" "dr" {
  count    = var.enable_dr ? 1 : 0
  provider = aws.dr
  state    = "available"
}

module "primary_vpc" {
  source = "./modules/vpc"

  region             = var.primary_region
  vpc_cidr           = var.vpc_cidr
  availability_zones = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.primary.names, 0, 2)
  project_name       = var.project_name
  environment        = var.environment
}

module "primary_eks" {
  count  = var.enable_eks ? 1 : 0
  source = "./modules/eks"

  project_name = var.project_name
  environment  = var.environment
  cluster_name = var.eks_cluster_name != "" ? var.eks_cluster_name : "${var.project_name}-${var.environment}-eks"

  cluster_version = var.eks_cluster_version

  vpc_id             = module.primary_vpc.vpc_id
  vpc_cidr           = var.vpc_cidr
  private_subnet_ids = module.primary_vpc.private_subnet_ids
  public_subnet_ids  = module.primary_vpc.public_subnet_ids
  node_subnet_ids    = module.primary_vpc.public_subnet_ids

  endpoint_private_access = var.eks_endpoint_private_access
  endpoint_public_access  = var.eks_endpoint_public_access
  public_access_cidrs     = var.eks_public_access_cidrs
  cluster_log_types       = var.eks_cluster_log_types

  node_group_name     = "primary"
  node_instance_types = var.eks_node_instance_types
  node_capacity_type  = var.eks_node_capacity_type
  node_disk_size      = var.eks_node_disk_size
  node_desired_size   = var.eks_node_desired_size
  node_min_size       = var.eks_node_min_size
  node_max_size       = var.eks_node_max_size

  enable_irsa = var.eks_enable_irsa

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Stack       = "EKS"
  }
}

module "k8s_bootstrap" {
  count  = var.enable_k8s_bootstrap ? 1 : 0
  source = "./modules/k8s-bootstrap"

  providers = {
    kubernetes = kubernetes.eks
    helm       = helm.eks
  }

  project_name            = var.project_name
  environment             = var.environment
  app_namespace           = var.k8s_app_namespace
  observability_namespace = var.k8s_observability_namespace
  enable_metrics_server   = var.k8s_enable_metrics_server

  depends_on = [module.primary_eks]
}

module "k8s_autoscaling" {
  count  = var.enable_k8s_autoscaling ? 1 : 0
  source = "./modules/k8s-autoscaling"

  providers = {
    aws        = aws
    kubernetes = kubernetes.eks
    helm       = helm.eks
  }

  project_name      = var.project_name
  environment       = var.environment
  region            = var.primary_region
  cluster_name      = module.primary_eks[0].cluster_name
  oidc_provider_arn = module.primary_eks[0].oidc_provider_arn
  oidc_issuer_url   = module.primary_eks[0].oidc_issuer_url
  app_namespace     = var.k8s_app_namespace

  enable_cluster_autoscaler        = var.k8s_enable_cluster_autoscaler
  enable_vpa                       = var.k8s_enable_vpa
  enable_vpa_resource              = var.k8s_enable_vpa_resource
  enable_hpa_demo                  = var.k8s_enable_hpa_demo
  cluster_autoscaler_chart_version = var.k8s_cluster_autoscaler_chart_version
  vpa_chart_version                = var.k8s_vpa_chart_version
  hpa_target_deployment_name       = var.k8s_hpa_target_deployment_name

  depends_on = [module.primary_eks, module.k8s_bootstrap]
}

module "k8s_observability" {
  count  = var.enable_k8s_observability ? 1 : 0
  source = "./modules/k8s-observability"

  providers = {
    kubernetes = kubernetes.eks
    helm       = helm.eks
  }

  project_name                   = var.project_name
  environment                    = var.environment
  observability_namespace        = var.k8s_observability_namespace
  enable_prometheus_stack        = var.k8s_enable_prometheus_stack
  enable_jaeger                  = var.k8s_enable_jaeger
  prometheus_stack_chart_version = var.k8s_prometheus_stack_chart_version
  jaeger_chart_version           = var.k8s_jaeger_chart_version
  prometheus_retention           = var.k8s_prometheus_retention
  grafana_admin_password         = var.k8s_grafana_admin_password

  depends_on = [module.primary_eks, module.k8s_bootstrap]
}

module "primary_security" {
  source = "./modules/security"

  vpc_id              = module.primary_vpc.vpc_id
  project_name        = var.project_name
  environment         = var.environment
  allowed_cidr_blocks = var.allowed_cidr_blocks
}

module "primary_rds" {
  source = "./modules/rds"

  vpc_id               = module.primary_vpc.vpc_id
  private_subnet_ids   = module.primary_vpc.private_subnet_ids
  security_group_id    = module.primary_security.rds_security_group_id
  project_name         = var.project_name
  environment          = var.environment
  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_engine_version    = var.db_engine_version
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = var.db_password
}

module "primary_s3" {
  source = "./modules/s3"

  region       = var.primary_region
  project_name = var.project_name
  environment  = var.environment
}

module "primary_waf" {
  source       = "./modules/waf"
  project_name = var.project_name
  environment  = var.environment
  rate_limit_per_ip = var.waf_rate_limit_per_ip

  providers = {
    aws           = aws.us_east_1
    aws.us_east_1 = aws.us_east_1
  }
}


module "primary_cloudfront" {
  source = "./modules/cloudfront"

  s3_bucket_domain = module.primary_s3.bucket_domain_name
  project_name     = var.project_name
  environment      = var.environment
  web_acl_id       = module.primary_waf.web_acl_arn
  alb_dns_name     = module.primary_alb.alb_dns_name
}

module "primary_alb" {
  source = "./modules/alb"

  vpc_id            = module.primary_vpc.vpc_id
  public_subnet_ids = module.primary_vpc.public_subnet_ids
  security_group_id = module.primary_security.alb_security_group_id
  project_name      = var.project_name
  environment       = var.environment
}

module "waf_alb" {
  source       = "./modules/waf-alb"
  project_name = var.project_name
  environment  = var.environment
  alb_arn      = module.primary_alb.lb_arn
  rate_limit_per_ip = var.waf_alb_rate_limit_per_ip
}


module "primary_ec2" {
  source = "./modules/ec2"

  vpc_id                    = module.primary_vpc.vpc_id
  private_subnet_ids        = module.primary_vpc.private_subnet_ids
  public_subnet_ids         = module.primary_vpc.public_subnet_ids
  security_group_id         = module.primary_security.ec2_security_group_id
  target_group_arn          = module.primary_alb.target_group_arn
  instance_type             = var.instance_type
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  project_name              = var.project_name
  environment               = var.environment
  key_pair_name             = var.key_pair_name
  db_endpoint               = module.primary_rds.db_endpoint
  db_name                   = var.db_name
  db_username               = var.db_username
  db_password               = var.db_password
  s3_bucket_name            = module.primary_s3.bucket_name
  cloudfront_url            = module.primary_cloudfront.distribution_url
  prestashop_version        = var.prestashop_version
  php_version               = var.php_version
  prestashop_admin_email    = var.prestashop_admin_email
  prestashop_admin_password = var.prestashop_admin_password
  prestashop_domain         = var.prestashop_domain != "" ? var.prestashop_domain : module.primary_alb.alb_dns_name
  region                    = var.primary_region
}

module "primary_cloudwatch" {
  source = "./modules/cloudwatch"

  project_name          = var.project_name
  environment           = var.environment
  region                = var.primary_region
  autoscaling_group     = module.primary_ec2.autoscaling_group_name
  rds_instance_id       = module.primary_rds.db_instance_id
  alb_target_group_arn  = module.primary_alb.target_group_arn
  alb_arn_suffix        = module.primary_alb.alb_arn_suffix
  alarm_email_endpoints = var.cloudwatch_alarm_email_endpoints
}

module "dr_vpc" {
  count  = var.enable_dr ? 1 : 0
  source = "./modules/vpc"

  providers = {
    aws = aws.dr
  }

  region             = var.dr_region
  vpc_cidr           = "10.1.0.0/16"
  availability_zones = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.dr[0].names, 0, 2)
  project_name       = var.project_name
  environment        = "${var.environment}-dr"
}

module "dr_security" {
  count  = var.enable_dr ? 1 : 0
  source = "./modules/security"

  providers = {
    aws = aws.dr
  }

  vpc_id              = module.dr_vpc[0].vpc_id
  project_name        = var.project_name
  environment         = "${var.environment}-dr"
  allowed_cidr_blocks = var.allowed_cidr_blocks
}

module "dr_alb" {
  count  = var.enable_dr ? 1 : 0
  source = "./modules/alb"

  providers = {
    aws = aws.dr
  }

  vpc_id            = module.dr_vpc[0].vpc_id
  public_subnet_ids = module.dr_vpc[0].public_subnet_ids
  security_group_id = module.dr_security[0].alb_security_group_id
  project_name      = var.project_name
  environment       = "${var.environment}-dr"
}

module "dr_ec2" {
  count  = var.enable_dr ? 1 : 0
  source = "./modules/ec2"

  providers = {
    aws = aws.dr
  }

  vpc_id                    = module.dr_vpc[0].vpc_id
  private_subnet_ids        = module.dr_vpc[0].private_subnet_ids
  public_subnet_ids         = module.dr_vpc[0].public_subnet_ids
  security_group_id         = module.dr_security[0].ec2_security_group_id
  target_group_arn          = module.dr_alb[0].target_group_arn
  instance_type             = var.instance_type
  min_size                  = 0
  max_size                  = var.max_size
  desired_capacity          = 0
  project_name              = var.project_name
  environment               = "${var.environment}-dr"
  key_pair_name             = var.key_pair_name
  db_endpoint               = module.primary_rds.db_endpoint
  db_name                   = var.db_name
  db_username               = var.db_username
  db_password               = var.db_password
  s3_bucket_name            = module.primary_s3.bucket_name
  cloudfront_url            = module.primary_cloudfront.distribution_url
  prestashop_version        = var.prestashop_version
  php_version               = var.php_version
  prestashop_admin_email    = var.prestashop_admin_email
  prestashop_admin_password = var.prestashop_admin_password
  prestashop_domain         = var.prestashop_domain != "" ? var.prestashop_domain : module.dr_alb[0].alb_dns_name
  region                    = var.dr_region
}

module "dr_cloudwatch" {
  count  = var.enable_dr ? 1 : 0
  source = "./modules/cloudwatch"

  providers = {
    aws = aws.dr
  }

  project_name          = var.project_name
  environment           = "${var.environment}-dr"
  region                = var.dr_region
  autoscaling_group     = module.dr_ec2[0].autoscaling_group_name
  rds_instance_id       = module.primary_rds.db_instance_id
  alb_target_group_arn  = module.dr_alb[0].target_group_arn
  alb_arn_suffix        = module.dr_alb[0].alb_arn_suffix
  alarm_email_endpoints = var.cloudwatch_alarm_email_endpoints
}
