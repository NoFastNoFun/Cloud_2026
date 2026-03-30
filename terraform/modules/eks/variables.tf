variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.30"
}

variable "vpc_id" {
  description = "VPC id where EKS runs"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block used to authorize control-plane traffic from worker nodes"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for control plane and worker nodes"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnets optionally exposed for API endpoint routing"
  type        = list(string)
  default     = []
}

variable "node_subnet_ids" {
  description = "Subnets used by worker nodes (empty = private_subnet_ids)"
  type        = list(string)
  default     = []
}

variable "endpoint_private_access" {
  description = "Whether EKS API endpoint is private"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Whether EKS API endpoint is public"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to access public EKS endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_log_types" {
  description = "Enabled EKS control-plane logs"
  type        = list(string)
  default     = ["api", "audit", "authenticator"]
}

variable "node_group_name" {
  description = "Managed node group name"
  type        = string
  default     = "default-ng"
}

variable "node_instance_types" {
  description = "Worker node instance types"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "ON_DEMAND or SPOT"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "node_capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "node_disk_size" {
  description = "Root volume size in GiB"
  type        = number
  default     = 30
}

variable "node_desired_size" {
  description = "Desired worker node count"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Min worker node count"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Max worker node count"
  type        = number
  default     = 6
}

variable "enable_irsa" {
  description = "Create IAM OIDC provider for IRSA"
  type        = bool
  default     = true
}

variable "oidc_thumbprint_list" {
  description = "OIDC provider thumbprints"
  type        = list(string)
  default     = ["9e99a48a9960b14926bb7f3b02e22da0afd40b87"]
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
