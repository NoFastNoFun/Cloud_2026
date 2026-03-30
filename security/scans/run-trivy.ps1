param(
  [string]$TargetPath = ".",
  [string]$OutputFile = "reports/trivy-fs.json"
)

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutputFile) | Out-Null
trivy fs --format json --output $OutputFile $TargetPath
