# Data sources
data "aws_availability_zones" "primary" {
  state = "available"
}

data "aws_availability_zones" "dr" {
  count    = var.enable_dr ? 1 : 0
  provider = aws.dr
  state    = "available"
}

# Primary Region - VPC Module
module "primary_vpc" {
  source = "./modules/vpc"

  region             = var.primary_region
  vpc_cidr           = var.vpc_cidr
  availability_zones = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.primary.names, 0, 2)
  project_name       = var.project_name
  environment        = var.environment
}

# Primary Region - Security Groups
module "primary_security" {
  source = "./modules/security"

  vpc_id              = module.primary_vpc.vpc_id
  project_name        = var.project_name
  environment         = var.environment
  allowed_cidr_blocks = var.allowed_cidr_blocks
}

# Primary Region - RDS Module
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

# Primary Region - S3 Module
module "primary_s3" {
  source = "./modules/s3"

  region       = var.primary_region
  project_name = var.project_name
  environment  = var.environment
}

# Primary Region - CloudFront Module
module "primary_cloudfront" {
  source = "./modules/cloudfront"

  s3_bucket_domain = module.primary_s3.bucket_domain_name
  project_name     = var.project_name
  environment      = var.environment
}

# Primary Region - ALB Module
module "primary_alb" {
  source = "./modules/alb"

  vpc_id            = module.primary_vpc.vpc_id
  public_subnet_ids = module.primary_vpc.public_subnet_ids
  security_group_id = module.primary_security.alb_security_group_id
  project_name      = var.project_name
  environment       = var.environment
}

# Primary Region - EC2 Module
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

# Primary Region - CloudWatch Module
module "primary_cloudwatch" {
  source = "./modules/cloudwatch"

  project_name      = var.project_name
  environment       = var.environment
  autoscaling_group = module.primary_ec2.autoscaling_group_name
  rds_instance_id   = module.primary_rds.db_instance_id
}

# DR Region - VPC Module (conditional)
module "dr_vpc" {
  count  = var.enable_dr ? 1 : 0
  source = "./modules/vpc"

  providers = {
    aws = aws.dr
  }

  region             = var.dr_region
  vpc_cidr           = "10.1.0.0/16" # Different CIDR for DR
  availability_zones = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.dr[0].names, 0, 2)
  project_name       = var.project_name
  environment        = "${var.environment}-dr"
}

# DR Region - Security Groups (conditional)
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

# DR Region - ALB Module (conditional, minimal setup)
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

# DR Region - EC2 Module (conditional, minimal setup - can scale up on failover)
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
  min_size                  = 0 # DR starts with 0 instances
  max_size                  = var.max_size
  desired_capacity          = 0 # DR starts with 0 instances
  project_name              = var.project_name
  environment               = "${var.environment}-dr"
  key_pair_name             = var.key_pair_name
  db_endpoint               = module.primary_rds.db_endpoint # DR can use primary DB or have its own
  db_name                   = var.db_name
  db_username               = var.db_username
  db_password               = var.db_password
  s3_bucket_name            = module.primary_s3.bucket_name # Can share S3 or have separate
  cloudfront_url            = module.primary_cloudfront.distribution_url
  prestashop_version        = var.prestashop_version
  php_version               = var.php_version
  prestashop_admin_email    = var.prestashop_admin_email
  prestashop_admin_password = var.prestashop_admin_password
  prestashop_domain         = var.prestashop_domain != "" ? var.prestashop_domain : module.dr_alb[0].alb_dns_name
  region                    = var.dr_region
}

