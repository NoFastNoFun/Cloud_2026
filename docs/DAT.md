# DAT - Technical Architecture Document

Project: `GreenLeaf`  
Context: Black Friday preparation on AWS  
Scope: Infrastructure and operations only (IaC, security, scalability, monitoring, FinOps)

## 1. Architecture Summary

The platform is deployed on AWS with Terraform modules:

- Edge: CloudFront + WAF
- Entry: Application Load Balancer
- Compute: EC2 Auto Scaling Group
- Data: RDS MySQL + RDS Proxy
- Storage: S3 (assets and backups)
- Monitoring: CloudWatch alarms, logs, dashboard, SNS notifications
- Optional DR: second region resources (disabled by default)

## 2. Logical Diagram

```text
Internet
  |
CloudFront + WAF (global)
  |
ALB (eu-west-1)
  |
EC2 ASG (app nodes)
  |
RDS Proxy
  |
RDS MySQL

Side systems:
- S3 static assets
- S3 backups
- CloudWatch logs/alarms/dashboard
- SNS alarm notifications
```

## 3. Terraform Structure

- Root orchestration: `terraform/main.tf`
- Shared variables: `terraform/variables.tf`
- Providers and regions: `terraform/providers.tf`
- Backend state: `terraform/backend.tf`
- Reusable modules:
  - `modules/vpc`
  - `modules/security`
  - `modules/alb`
  - `modules/ec2`
  - `modules/rds`
  - `modules/s3`
  - `modules/cloudfront`
  - `modules/waf`
  - `modules/waf-alb`
  - `modules/cloudwatch`

## 4. Availability and Scalability

- Multi-AZ subnets are created from selected availability zones.
- ALB distributes traffic to EC2 instances.
- Auto Scaling policies support elastic scaling.
- DR region can be enabled for failover preparation.

Known constraint:
- Current app stack is EC2 ASG based, not Kubernetes/EKS.

## 5. Security Design

- Network segmentation with public/private subnets.
- Security groups isolate ALB, EC2, and RDS tiers.
- WAF rules protect edge and ALB (managed rules + rate limit).
- Encryption at rest on key data resources.
- IAM role for EC2 and required service permissions.
- Secrets Manager is used for RDS proxy authentication.

## 6. Observability

- CloudWatch alarms:
  - EC2 CPU / memory
  - RDS CPU / connections / storage
  - ALB response time / unhealthy hosts / 5xx
- CloudWatch log groups for nginx and system logs.
- CloudWatch dashboard for consolidated operations view.
- SNS topic for alert notifications.

## 7. DR Strategy

- Secondary region infrastructure can be enabled with `enable_dr = true`.
- DR compute starts at zero desired capacity for cost control.
- Failover process is documented in runbook.

## 8. Operational Documents

- Deployment guide: `docs/Deployment_Guide.md`
- CloudWatch guide: `docs/CloudWatch_Guide.md`
- Incident runbook: `docs/Runbook_Incident_BlackFriday.md`
- Post-mortem template: `docs/Postmortem_BlackFriday_Template.md`
- ADRs: `docs/ADRs/`

## 9. Risks and Gaps

1. Performance target proof (90k users) is not automatic and must be demonstrated with load test reports.
2. Security scans (Trivy/ZAP) need execution outputs for final evidence.
3. Grafana/Jaeger evidence depends on tooling rollout in runtime environment.
