# Validation Checklist - Cahier des charges

Status date: 2026-04-01

## 1. Security evidence

- [ ] Execute Trivy scan and archive outputs in `evidence/security`.
- [ ] Execute ZAP baseline and archive outputs in `evidence/security`.
- [ ] Record critical findings and mitigation in DAT appendix.

Reference: DAT risk/gap requires scan evidence.

## 2. Observability evidence

- [ ] Capture alarm states before/during/after load test.
- [ ] Archive load-test summary JSON used for validation.
- [ ] Capture dashboard screenshot during load.
- [ ] Archive representative application error logs.

Reference: CloudWatch guide + load testing evidence policy.

## 3. DR/failover drill evidence

- [ ] Run one failover simulation (scale DR capacity up).
- [ ] Validate basic health endpoint in DR.
- [ ] Roll back DR capacity to baseline.
- [ ] Archive timeline and command outputs in `evidence/dr`.
- [ ] Update incident runbook lessons learned.

Reference: Runbook + DAT DR strategy.

## 4. FinOps governance evidence

- [ ] Export Cost Explorer usage/cost by service.
- [ ] Export AWS Budgets configuration.
- [ ] Export cost split by Project tag.
- [ ] Update weekly report table with one real snapshot.

Reference: FinOps report section "Evidence to attach".

## 5. Final acceptance gates

- [ ] Security scans archived and reviewed.
- [ ] Observability proof archived.
- [ ] DR drill archived.
- [ ] FinOps annex archived.
- [ ] Final presentation updated with these artifacts.

## Recommended execution order

1. Observability capture (can reuse next load test window).
2. Security scans.
3. DR drill (short controlled window).
4. FinOps exports.
5. Presentation and DAT appendix update.
