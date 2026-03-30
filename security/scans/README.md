# Security Scans - Evidence Guide

This folder is used to store scan outputs for evaluation evidence.

## 1. Trivy (image or filesystem)

Example filesystem scan:

```bash
trivy fs --format json --output reports/trivy-fs.json .
```

Example container image scan:

```bash
trivy image --format json --output reports/trivy-image.json your-image:tag
```

## 2. OWASP ZAP (baseline)

Example baseline scan (docker):

```bash
docker run --rm -v ${PWD}:/zap/wrk ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py -t https://your-endpoint -r reports/zap-baseline.html
```

## 3. Evidence Expected

Keep at least:

1. `reports/trivy-*.json`
2. `reports/zap-*.html`
3. A short remediation note per critical/high finding
