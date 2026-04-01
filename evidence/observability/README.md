# Observability Evidence

Objective: prove dashboards, alarms, and logs during load tests.

## Required files

1. `alarms-before.json`
2. `alarms-during.json`
3. `alarms-after.json`
4. `dashboard.png` (manual screenshot from AWS Console)
5. `logs-nginx-error.txt`
6. `k6-summary.json` (copy from tests/load/results)

## Commands

```powershell
Set-Location C:\Users\banda\source\repos\Cloud_2026

$region = "eu-west-1"
$dashName = "greenleaf-prod-dashboard"

aws cloudwatch describe-alarms --region $region > .\evidence\observability\alarms-before.json

# Run k6 test in another terminal, then capture during test
aws cloudwatch describe-alarms --region $region > .\evidence\observability\alarms-during.json

# After test
aws cloudwatch describe-alarms --region $region > .\evidence\observability\alarms-after.json
aws logs tail /aws/ec2/greenleaf/prod/nginx/error --since 2h > .\evidence\observability\logs-nginx-error.txt
Copy-Item .\tests\load\results\summary-quick-v4.json .\evidence\observability\k6-summary.json -Force
```

## Manual capture

1. Open CloudWatch dashboard `greenleaf-prod-dashboard`.
2. Take one screenshot during load and save as `dashboard.png`.

## Validation criteria

1. Alarm states and timestamps are archived.
2. k6 summary and logs are archived.
3. Dashboard screenshot is present.
