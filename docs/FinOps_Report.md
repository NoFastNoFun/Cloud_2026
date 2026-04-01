# FinOps Report - Black Friday Preparation

Project: `GreenLeaf`  
Period: training project  
Owner: team operations

## 1. Objective

Control cloud spending while preserving performance and reliability targets for high traffic events.

Scope note: this report is focused on GreenLeaf only. Other account-level budgets and projects are out of scope.

## 2. Cost Baseline (estimated)

Reference configuration (cost-optimized profile):

- EC2 (`t3.small`, low baseline capacity)
- RDS (`db.t3.small`)
- ALB (single primary region by default)
- NAT instance instead of NAT gateway
- CloudWatch limited retention
- DR disabled by default

Estimated monthly baseline: around `$75-$100` (environment dependent).

## 3. Cost Drivers

Main contributors:

1. Compute scale-out during peak load tests
2. RDS class and storage growth
3. ALB + data processing
4. CloudFront transfer and requests
5. CloudWatch ingestion and retention

## 4. Optimization Decisions Implemented

1. Rightsized default EC2 and RDS classes for baseline.
2. Low default desired capacity with Auto Scaling for burst traffic.
3. DR region set as optional (`enable_dr = false` by default).
4. Log retention reduced for non-critical logs.
5. NAT instance selected as cost-effective option for this context.
6. EKS and Kubernetes add-ons are disabled by default in `terraform.tfvars` to preserve baseline budget.
7. If EKS is enabled for demo, node group is constrained (`t3.small`, `SPOT`, min 0 / desired 1 / max 1).

## 5. Budget Governance

Recommended controls:

1. AWS Budget monthly cap with threshold alerts (50/80/100%).
2. Daily Cost Explorer review during load-test week.
3. Tag-based cost tracking per environment and component.
4. Stop idle non-production resources outside active work windows.

## 6. KPI Tracking

Track weekly:

- Total monthly forecast
- Spend by service (EC2, RDS, ALB, CloudFront, CloudWatch)
- Cost per load-test campaign
- Delta vs previous week

## 7. Suggested Weekly Report Table

| Week | Actual Cost | Forecast | Top Service | Action |
|---|---:|---:|---|---|
| W1 | TBD | TBD | TBD | TBD |
| W2 | TBD | TBD | TBD | TBD |
| W3 | TBD | TBD | TBD | TBD |

## 8. Evidence to Attach for Final Review

1. Cost Explorer export (project period)
2. Budget alerts screenshots
3. Tag-based cost split snapshot
4. Before/after optimization notes

## 9. Risks

1. Aggressive load tests can spike cost quickly.
2. 90k user simulations may require distributed generators and temporary overprovisioning.
3. Insufficient tagging reduces cost attribution quality.
4. Keeping EKS permanently enabled typically exceeds the $75-$100 monthly baseline.

## 10. Evidence status (2026-04-01)

- AWS Budgets export archived in `evidence/finops/budget-list.json`.
- Weekly FinOps snapshot archived in `evidence/finops/weekly-report.md`.
- Cost Explorer export by service could not be produced because `ce:GetCostAndUsage` is blocked by `DenyBillingAccess`.
- Cost split by tag `Project` is blocked by the same Billing denial policy.
- No GreenLeaf-dedicated budget was found in the current AWS Budgets export.
- Non-GreenLeaf budgets in the account are intentionally excluded from analysis.
