# Final Presentation Outline (15 min + 10 min Q&A)

## 1. Problem and Objectives (2 min)

- Black Friday context
- Evaluation targets:
  - 90k users objective
  - latency < 2s
  - errors < 1%

## 2. Architecture (3 min)

- Terraform modular design
- Traffic path (CloudFront/WAF -> ALB -> ASG -> RDS)
- DR approach

## 3. Security (2 min)

- IAM and network controls
- WAF rules and rate limiting
- Secrets and encryption

## 4. Observability (2 min)

- CloudWatch alarms, logs, dashboard
- Alerting flow and incident visibility

## 5. Performance and Load Tests (3 min)

- k6 strategy and stages
- Results summary:
  - peak concurrent users reached
  - p95 latency
  - error rate

## 6. FinOps and Governance (2 min)

- Cost baseline and optimizations
- Budget controls and weekly reporting

## 7. Lessons Learned and Next Steps (1 min)

- What improved
- Remaining gaps
- Priority roadmap

## Q&A Support Material

Keep these ready in backup slides:

1. ADR list
2. Runbook excerpt
3. Post-mortem sample
4. Terraform module map
