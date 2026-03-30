variable "primary_region" {
  description = "Primary AWS region (Ireland)"
  type        = string
  default     = "eu-west-1"
}

variable "dr_region" {
  description = "Disaster recovery AWS region (Frankfurt)"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment name (e.g., prod, staging)"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "greenleaf"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = []
}

variable "instance_type" {
  description = "EC2 instance type for PrestaShop servers"
  type        = string
  default     = "t3.small"
}

variable "min_size" {
  description = "Minimum number of instances in Auto Scaling Group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in Auto Scaling Group"
  type        = number
  default     = 6
}

variable "desired_capacity" {
  description = "Desired number of instances in Auto Scaling Group"
  type        = number
  default     = 1
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.small"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 50
}

variable "db_engine_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.0"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "prestashop"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "prestashop_admin_email" {
  description = "PrestaShop admin email"
  type        = string
  default     = "admin@greenleaf.example.com"
}

variable "prestashop_admin_password" {
  description = "PrestaShop admin password"
  type        = string
  sensitive   = true
}

variable "prestashop_domain" {
  description = "PrestaShop domain (will be set to ALB DNS if empty)"
  type        = string
  default     = ""
}

variable "enable_dr" {
  description = "Enable disaster recovery region (minimal resources)"
  type        = bool
  default     = false
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "key_pair_name" {
  description = "AWS Key Pair name for EC2 instances"
  type        = string
  default     = ""
}

variable "prestashop_version" {
  description = "PrestaShop version (e.g., 8.* for latest 8.x)"
  type        = string
  default     = "8.*"
}

variable "php_version" {
  description = "PHP version to install"
  type        = string
  default     = "8.2"
}

variable "cloudwatch_alarm_email_endpoints" {
  description = "List of email addresses to receive CloudWatch alarm notifications"
  type        = list(string)
  default     = []
}

variable "enable_eks" {
  description = "Enable EKS cluster deployment in primary region"
  type        = bool
  default     = false
}

variable "eks_cluster_name" {
  description = "EKS cluster name override (empty = auto naming)"
  type        = string
  default     = ""
}

variable "eks_cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.30"
}

variable "eks_endpoint_private_access" {
  description = "Enable private access to EKS API endpoint"
  type        = bool
  default     = true
}

variable "eks_endpoint_public_access" {
  description = "Enable public access to EKS API endpoint"
  type        = bool
  default     = true
}

variable "eks_public_access_cidrs" {
  description = "CIDR list allowed for public access to EKS API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_cluster_log_types" {
  description = "Enabled EKS control-plane log types"
  type        = list(string)
  default     = ["api", "audit", "authenticator"]
}

variable "eks_node_instance_types" {
  description = "EKS managed node group instance types"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_capacity_type" {
  description = "Capacity type for EKS managed node group (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "eks_node_disk_size" {
  description = "Disk size in GiB for EKS worker nodes"
  type        = number
  default     = 30
}

variable "eks_node_desired_size" {
  description = "Desired size for EKS managed node group"
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "Minimum size for EKS managed node group"
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Maximum size for EKS managed node group"
  type        = number
  default     = 6
}

variable "eks_enable_irsa" {
  description = "Create IAM OIDC provider for EKS IRSA"
  type        = bool
  default     = true
}
