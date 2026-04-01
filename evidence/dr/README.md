# DR Evidence

Objective: prove a documented failover drill.

## Required files

1. `dr-test-plan.md`
2. `dr-timeline.md`
3. `dr-before.json`
4. `dr-after-scaleup.json`
5. `dr-healthcheck.txt`
6. `dr-rollback.json`

## Commands example (adjust names)

```powershell
Set-Location C:\Users\banda\source\repos\Cloud_2026

$drRegion = "eu-central-1"
$drAsg = "greenleaf-dr-asg"

aws autoscaling describe-auto-scaling-groups --region $drRegion --auto-scaling-group-names $drAsg > .\evidence\dr\dr-before.json

# Simulate DR activation
aws autoscaling update-auto-scaling-group --region $drRegion --auto-scaling-group-name $drAsg --min-size 1 --desired-capacity 1 --max-size 2
Start-Sleep -Seconds 60

aws autoscaling describe-auto-scaling-groups --region $drRegion --auto-scaling-group-names $drAsg > .\evidence\dr\dr-after-scaleup.json

# Optional health check
"http://<dr-alb-dns>/healthz" | Out-File .\evidence\dr\dr-healthcheck.txt

# Rollback to baseline
aws autoscaling update-auto-scaling-group --region $drRegion --auto-scaling-group-name $drAsg --min-size 0 --desired-capacity 0 --max-size 1
aws autoscaling describe-auto-scaling-groups --region $drRegion --auto-scaling-group-names $drAsg > .\evidence\dr\dr-rollback.json
```

## Validation criteria

1. Clear timeline with start/end and decision points.
2. Scale-up and rollback proof present.
3. Runbook updated with lessons learned.
