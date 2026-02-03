terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Optional: Uncomment to use S3 backend for state management
  # backend "s3" {
  #   bucket = "greenleaf-terraform-state"
  #   key    = "terraform.tfstate"
  #   region = "eu-west-1"
  # }
}

# Primary region provider (Ireland)
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

# DR region provider (Frankfurt)
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

