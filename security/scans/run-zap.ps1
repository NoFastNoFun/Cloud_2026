param(
  [Parameter(Mandatory = $true)]
  [string]$TargetUrl,
  [string]$OutputFile = "reports/zap-baseline.html"
)

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutputFile) | Out-Null

docker run --rm -v "${PWD}:/zap/wrk" ghcr.io/zaproxy/zaproxy:stable `
  zap-baseline.py -t $TargetUrl -r $OutputFile
