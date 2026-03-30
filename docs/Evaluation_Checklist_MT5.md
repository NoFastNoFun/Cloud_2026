# Evaluation Checklist - Black Friday MT5

This file maps the project repository to the evaluation criteria from:
`BlackFriday_CahierDesCharges MT5.pdf`

## 1. Infrastructure as Code

Status: `Documented and applied`

- Terraform modules and root orchestration are present in `terraform/`.
- Remote state backend is configured (`S3 + DynamoDB lock`).
- Deployment guide is present in `docs/Deployment_Guide.md`.
- Architecture document is present in `docs/DAT.md`.

Evidence files:
- `terraform/main.tf`
- `terraform/backend.tf`
- `terraform/bootstrap/main.tf`
- `docs/Deployment_Guide.md`
- `docs/DAT.md`

## 2. Cloud Security

Status: `Partially demonstrated`

- Security Groups for ALB, EC2, and RDS.
- WAF for CloudFront and ALB.
- Secrets Manager resource for DB proxy auth.
- Cloud encryption enabled on key storage resources.

Evidence files:
- `terraform/modules/security/main.tf`
- `terraform/modules/waf/main.tf`
- `terraform/modules/waf-alb/main.tf`
- `terraform/modules/rds/main.tf`
- `security/scans/README.md`

Still to prove during demo:
- Actual vulnerability scan outputs (Trivy/ZAP reports).

## 3. Black Friday Performance

Status: `Framework ready, execution proof required`

- Auto Scaling Group and scaling policies are configured.
- Load test scenario script for progressive ramp-up to 90k users is available.
- Pass/fail thresholds aligned to requirements:
  - p95 latency < 2s
  - error rate < 1%

Evidence files:
- `terraform/modules/ec2/main.tf`
- `tests/load/k6_blackfriday.js`
- `tests/load/README.md`

Still to prove during demo:
- Real execution reports showing 90k behavior.

## 4. Observability and Dashboards

Status: `Validated in live cluster (core stack)`

- CloudWatch alarms, logs, SNS notifications, and dashboard are configured.
- Kubernetes observability module is implemented and deployed (Prometheus/Grafana/Jaeger via Helm).
- Grafana dashboard export template is added for deliverable completeness.

Evidence files:
- `terraform/modules/cloudwatch/main.tf`
- `terraform/modules/k8s-observability/`
- `docs/CloudWatch_Guide.md`
- `docs/Grafana_Dashboard_Export.json`

Still to prove during demo:
- Final exported dashboard tied to your live environment.
- Tracing proof if Jaeger is required by jury.

Live validation already done:
- `helm list -n observability` shows `kube-prometheus-stack` and `jaeger` as deployed.
- `kubectl -n observability get svc` shows Grafana/Prometheus/Alertmanager/Jaeger services.
- `kubectl top nodes` returns metrics after metrics-server installation.

## 5. FinOps and Budget Management

Status: `Documented`

- FinOps report with estimation, controls, and tracking process.
- Cost optimization actions documented.

Evidence files:
- `docs/FinOps_Report.md`
- `docs/Deployment_Guide.md`
- `terraform/terraform.tfvars.example`

Still to prove during demo:
- Real AWS cost report screenshots / exports for the project period.

## 6. Documentation and Post-Mortem

Status: `Now covered in repository`

- ADR folder and ADR documents.
- Incident runbook.
- Post-mortem template.
- Presentation outline.

Evidence files:
- `docs/ADRs/`
- `docs/Runbook_Incident_BlackFriday.md`
- `docs/Postmortem_BlackFriday_Template.md`
- `docs/Presentation_Outline.md`

## 7. Kubernetes / Autoscaling Runtime

Status: `Validated`

- EKS cluster and nodegroup are active (`greenleaf-prod-eks` / `greenleaf-prod-primary`).
- K8s bootstrap is applied (namespaces + RBAC + metrics-server).
- Autoscaling stack is applied (Cluster Autoscaler + HPA + VPA with CRD then resource flow).

Evidence files:
- `terraform/modules/eks/`
- `terraform/modules/k8s-bootstrap/`
- `terraform/modules/k8s-autoscaling/`
- `docs/EKS_Gap_Audit.md`

## 8. Demo Day Evidence Pack (to produce)

Before final evaluation, collect these proofs:

1. `k6` result files:
- `tests/load/results/summary.json`
- `tests/load/results/console.txt`

2. Security reports:
- `security/scans/reports/trivy-*.json`
- `security/scans/reports/zap-*.html`

3. Observability exports:
- Final Grafana dashboard JSON from your real stack.
- CloudWatch alarm status screenshots.

4. Budget proof:
- AWS Cost Explorer export for project timeline.
- Budget alert configuration screenshots.
