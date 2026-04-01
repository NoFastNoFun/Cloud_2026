# Runbook Incident - Black Friday

This runbook is for live incident response during peak traffic simulation.

## 1. Roles

- Incident Commander: drives decisions and priorities
- Ops Lead: infrastructure actions
- App Lead: application checks
- Scribe: timeline and decisions log
- Communications: status updates to stakeholders

## 2. Severity Levels

- `SEV1`: major outage or severe business impact
- `SEV2`: degraded service with workaround
- `SEV3`: minor issue with limited impact

## 3. First 10 Minutes Checklist

1. Declare severity and open incident channel.
2. Capture start time and first symptom.
3. Check ALB health, 5xx rate, response time.
4. Check EC2 ASG desired/in-service count.
5. Check RDS CPU/connections/storage.
6. Confirm whether WAF blocks are abnormal.

## 4. Scenario Playbooks

### A. High Latency (>2s p95)

1. Validate CloudWatch `TargetResponseTime`.
2. Confirm EC2 CPU/memory saturation.
3. Increase ASG desired capacity if needed.
4. Check DB connections and slow query pressure.
5. Verify no recent deploy/regression.

### B. Error Rate Spike (>1%)

1. Check ALB `HTTPCode_Target_5XX_Count`.
2. Inspect `/aws/ec2/.../nginx/error` log group.
3. Check instance health in target group.
4. Drain unhealthy instances and trigger refresh if needed.

### C. Unhealthy Targets

1. Validate `/healthz` endpoint from instance and via ALB.
2. Check user-data bootstrap logs.
3. Confirm app services are up (`nginx`, `php-fpm`).
4. Replace failed nodes via ASG.

### D. Database Saturation

1. Check RDS CPU and `DatabaseConnections`.
2. Verify RDS proxy status.
3. Reduce app pressure by scaling app nodes and limiting noisy traffic.
4. If needed, temporary vertical DB increase.

### E. Suspected Attack / Bot Storm

1. Check WAF sampled requests and blocked counts.
2. Tighten WAF rate limit rule if attack confirmed.
3. Keep incident notes for post-mortem and rule tuning.

## 5. Failover Procedure (if DR enabled)

1. Confirm primary instability exceeds recovery objective.
2. Scale DR ASG from zero to operational minimum.
3. Validate DR ALB health.
4. Update traffic routing strategy.
5. Announce status and monitor errors/latency.

## 6. Recovery Exit Criteria

Close incident only when:

1. p95 latency back below 2s
2. error rate below 1%
3. no active severe alarms
4. communication sent with recovery timestamp

## 7. Post-Incident Actions

1. Fill post-mortem template.
2. Open corrective actions with owner and due date.
3. Update this runbook if process gaps were found.

## 8. DR Drill Lesson Learned

- DR capacity can be scaled from 0 to 1 in eu-central-1, and the ASG reaches `InService`.
- During the current drill, the DR ALB health check returned HTTP 502, which indicates an application/bootstrap readiness problem rather than an autoscaling problem.
- Before a production failover sign-off, validate the DR user-data/bootstrap path, target-group health, and application endpoint response under the secondary region.
