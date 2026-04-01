# FinOps Evidence

Objective: archive proof required by FinOps report.

## Required files

1. `cost-explorer.json`
2. `budget-list.json`
3. `cost-by-tag-project.json`
4. `weekly-report.md`

## Commands

```powershell
Set-Location C:\Users\banda\source\repos\Cloud_2026

# Last 30 days window (adjust dates)
$start = (Get-Date).AddDays(-30).ToString("yyyy-MM-dd")
$end = (Get-Date).ToString("yyyy-MM-dd")

aws ce get-cost-and-usage `
  --time-period Start=$start,End=$end `
  --granularity DAILY `
  --metrics BlendedCost UnblendedCost `
  --group-by Type=DIMENSION,Key=SERVICE > .\evidence\finops\cost-explorer.json

aws budgets describe-budgets --account-id 622333992348 > .\evidence\finops\budget-list.json

aws ce get-cost-and-usage `
  --time-period Start=$start,End=$end `
  --granularity MONTHLY `
  --metrics UnblendedCost `
  --group-by Type=TAG,Key=Project > .\evidence\finops\cost-by-tag-project.json
```

## Validation criteria

1. Cost trend, budget config, and tag split archived.
2. Weekly report updated with actions.
3. Evidence aligned with FinOps_Report annex list.
