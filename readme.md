# GreenLeaf E-commerce Cloud Infrastructure

> **🚀 NEW: Simplified Deployment!** 
> This project now supports deployment with **Terraform only** - no Ansible required!
> See [Quick Start Guide](QUICK_START.md) for the fastest deployment method.

## 📖 Project Overview

This project involves designing, deploying, and documenting a scalable cloud infrastructure on **AWS** for **GreenLeaf**, a startup specializing in eco-friendly products. The goal is to host the **PrestaShop** e-commerce platform while ensuring high availability, security, and cost efficiency.

This repository contains the **Infrastructure as Code (IaC)** and **Configuration Management** scripts required to provision the environment from scratch.

## 🏗 Architecture & Technologies

The infrastructure is built to meet the following requirements:

- **Cloud Provider**: Amazon Web Services (AWS)
- **Application**: PrestaShop 8.x (latest stable)
- **Infrastructure as Code**: Terraform (with automated user_data configuration)
- **Configuration Management**: Built into user_data script (Ansible optional)
- **Regions**: Multi-region deployment (Ireland primary, Frankfurt DR)

**Key Features**:
- **High Availability**: Deployed across at least 2 Availability Zones (AZs) per region
- **Multi-Region**: Active-Passive setup with Ireland (primary) and Frankfurt (DR)
- **Scalability**: Auto Scaling Groups (2-6 instances) to handle traffic peaks
- **Security**: Best practices for data protection and network isolation
- **Monitoring**: CloudWatch alarms for proactive supervision
- **CDN**: CloudFront distribution for static assets

## 📂 Repository Structure

```
.
├── terraform/                    # Terraform configuration files (IaC)
│   ├── main.tf                   # Root module orchestrating all resources
│   ├── variables.tf              # Input variables
│   ├── outputs.tf                # Output values
│   ├── providers.tf              # AWS provider configuration (multi-region)
│   ├── versions.tf               # Terraform and provider version constraints
│   ├── terraform.tfvars.example  # Example variable values
│   └── modules/                  # Reusable modules
│       ├── vpc/                  # VPC, subnets, IGW, NAT gateways
│       ├── security/             # Security groups
│       ├── alb/                  # Application Load Balancer
│       ├── ec2/                  # Launch template, Auto Scaling Group
│       ├── rds/                  # RDS MySQL Multi-AZ
│       ├── s3/                   # S3 buckets for static assets and backups
│       ├── cloudfront/           # CloudFront distribution
│       └── cloudwatch/           # CloudWatch alarms and log groups
├── ansible/                      # Ansible playbooks (OPTIONAL - legacy)
│   ├── ansible.cfg               # Ansible configuration
│   ├── site.yml                  # Main playbook
│   ├── inventory/
│   │   └── aws_ec2.yml          # Dynamic AWS EC2 inventory
│   ├── group_vars/
│   │   └── all.yml              # Common variables
│   └── roles/
│       ├── common/              # System updates and basic packages
│       ├── nginx/               # Nginx installation and configuration
│       ├── php/                 # PHP 8.2 with PrestaShop extensions
│       ├── mysql-client/        # MySQL client installation
│       ├── prestashop/          # PrestaShop installation
│       └── cloudwatch-agent/   # CloudWatch agent configuration
│   NOTE: All configuration is now automated via user_data.sh
├── docs/                         # Project documentation
│   ├── DAT.md                    # Technical Architecture Document
│   ├── FinOps_Report.md          # Cost analysis and optimization strategies
│   └── Deployment_Guide.md      # Deployment and exploitation manual
└── README.md
```

## 🚀 Getting Started

### Prerequisites

Ensure you have the following tools installed:

- [AWS CLI](https://aws.amazon.com/cli/) (v2.x) configured with appropriate credentials
- [Terraform](https://www.terraform.io/) (>= 1.0)
- Git

**Note**: Ansible is NO LONGER REQUIRED. All configuration is automated via Terraform user_data scripts.

### Quick Start

1. **Clone the Repository**
```bash
git clone <repository-url>
cd Cloud_2026
```

2. **Configure Variables**
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values (especially passwords)
```

3. **Deploy Infrastructure (Single Command)**
```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

**That's it!** The deployment takes approximately 10-15 minutes. Everything is automated:
- Infrastructure provisioning
- Application installation (Nginx, PHP, PrestaShop)
- Database configuration
- Monitoring setup (CloudWatch)
- Security hardening

4. **Access the Application**
```bash
# Get the ALB DNS name
terraform output alb_dns_name

# Test health endpoint
curl http://<ALB_DNS>/healthz

# Access PrestaShop in browser
http://<ALB_DNS>
```

### Detailed Instructions

**New Deployment Method (Recommended)**: See [Deployment Without Ansible](DEPLOYMENT_WITHOUT_ANSIBLE.md) for the simplified Terraform-only approach.

**Legacy Method**: See [Deployment Guide](docs/Deployment_Guide.md) if you prefer using Ansible for configuration management.

**What Happens Automatically**:
- ✅ System packages installed and updated
- ✅ Nginx web server configured with PrestaShop optimizations
- ✅ PHP 8.2 with all required extensions
- ✅ PrestaShop downloaded and installed via Composer
- ✅ Database connection configured and verified
- ✅ CloudWatch monitoring and logging enabled
- ✅ Health checks configured
- ✅ Auto-scaling ready (new instances self-configure)



## 💰 FinOps & Budget

**Estimated Monthly Cost**: ~$75/month (optimized configuration)

**Cost Breakdown** (optimized):
- EC2 (1x t3.small): ~$15/month
- RDS (db.t3.small Single-AZ): ~$30/month
- ALB (1 region): ~$20/month
- NAT Instance: ~$5/month
- Other services (EBS, S3, CloudFront, CloudWatch): ~$5/month

**Note**: The infrastructure is optimized to stay under $100/month. Actual costs vary based on usage, traffic, and data storage.

**Optimization Strategy**: This project utilizes cost-effective resources and Auto Scaling to match demand. A full analysis of costs and optimization recommendations can be found in [FinOps Report](docs/FinOps_Report.md).

**Key Optimizations Available**:
- Reserved Instances: ~$63/month savings
- NAT Instance instead of NAT Gateway: ~$50/month savings
- CloudWatch log retention optimization: ~$2/month savings



## 📚 Documentation

All project documentation is available in the `docs/` directory:

- **[Technical Architecture Document (DAT)](docs/DAT.md)**: Complete architecture overview, network topology, security design, and component descriptions
- **[FinOps Report](docs/FinOps_Report.md)**: Detailed cost analysis, optimization strategies, and budget tracking recommendations
- **[Deployment Guide](docs/Deployment_Guide.md)**: Step-by-step deployment instructions, troubleshooting, and maintenance procedures

## 🏗 Infrastructure Components

### Primary Region (Ireland - eu-west-1)
- VPC with public/private subnets across 2+ AZs
- Application Load Balancer
- Auto Scaling Group (2-6 EC2 instances)
- RDS MySQL Multi-AZ
- S3 buckets (static assets + backups)
- CloudFront distribution
- CloudWatch alarms and log groups

### DR Region (Frankfurt - eu-central-1)
- VPC with minimal setup
- Application Load Balancer
- Auto Scaling Group (0 instances by default, can scale up on failover)

## 🔒 Security Features

- Network isolation (private subnets for EC2 and RDS)
- Security groups with least-privilege access
- Encryption at rest (EBS, RDS, S3)
- Encryption in transit (TLS/SSL via CloudFront and ALB)
- IAM roles with minimal required permissions
- No direct Internet access to application instances

## 📊 Monitoring

- **CloudWatch Alarms**: CPU, memory, disk usage, RDS metrics
- **CloudWatch Logs**: Nginx access/error logs, PrestaShop system logs
- **Auto Scaling**: Automatic scaling based on CPU utilization
- **Health Checks**: ALB health checks on `/health_check.php`

## 🛠 Maintenance

### Updating Infrastructure
```bash
cd terraform
# Edit configuration files
terraform plan
terraform apply
```

### Updating Application Configuration
```bash
# Edit terraform/modules/ec2/user_data.sh
# Then trigger instance replacement
terraform taint aws_autoscaling_group.prestashop
terraform apply
```

### Accessing Instances
```bash
# Via AWS Systems Manager (recommended - no SSH key needed)
aws ssm start-session --target <instance-id>

# Check deployment logs
sudo tail -f /var/log/user-data.log
```

### Monitoring Deployment
```bash
# View CloudWatch logs
aws logs tail /aws/ec2/greenleaf/prod/nginx/access --follow

# Check service status via SSM
aws ssm start-session --target <instance-id>
systemctl status nginx php-fpm
```

## 📝 Deliverables Checklist

- [x] Technical Architecture Document (DAT)
- [x] Source Code (Terraform & Ansible)
- [x] FinOps Report
- [x] Deployment & Exploitation Guide
- [ ] Final Presentation (to be created)

## 🤝 Contributing

This is a student project. For questions or issues, please refer to the documentation or contact the project team.

## 📄 License

This project is part of an academic assignment.

---

**Project Duration**: 1 week  
**Context**: Student Project  
**Last Updated**: 2026-01-05

pour créer une clé ssh 
aws ec2 create-key-pair --key-name greenleaf-key --query 'KeyMaterial' --output text > greenleaf-key.pem