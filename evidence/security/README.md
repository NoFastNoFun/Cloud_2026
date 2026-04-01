# Security Evidence

Objective: archive proof of security scans requested by DAT.

## Required files

1. `trivy-image.txt`
2. `trivy-fs.txt`
3. `zap-baseline.txt`
4. `zap-baseline.html` (optional)

## Commands (from repository root)

```powershell
Set-Location C:\Users\banda\source\repos\Cloud_2026

# Optional: create reports folder used by existing scripts
New-Item -ItemType Directory -Force .\security\scans\reports | Out-Null

# Trivy (if script exists and is configured)
.\security\scans\run-trivy.ps1 *> .\evidence\security\trivy-image.txt

# Filesystem scan fallback
trivy fs . --severity HIGH,CRITICAL *> .\evidence\security\trivy-fs.txt

# ZAP baseline
.\security\scans\run-zap.ps1 -TargetUrl "https://d1ielqbdwca1k7.cloudfront.net" *> .\evidence\security\zap-baseline.txt
```

## Validation criteria

1. Scan commands executed successfully.
2. No unresolved critical findings, or mitigation documented in DAT appendix.
3. Evidence files committed in `evidence/security`.
