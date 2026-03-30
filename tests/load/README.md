# Load Testing - k6

## Goal

Provide measurable evidence for Black Friday criteria:

- sustained high concurrency strategy up to 90k users
- p95 latency under 2 seconds
- error rate under 1%

## Files

- `k6_blackfriday.js`: progressive load scenario
- `results/`: output artifacts to keep for evaluation

## Prerequisites

1. Install k6
2. Set a valid base URL:
   - example: `https://your-cloudfront-domain`
   - or: `http://your-alb-dns-name`

## Run

```bash
k6 run -e BASE_URL=https://your-endpoint k6_blackfriday.js --summary-export results/summary.json
```

Quick run (recommended for local validation, ~10 minutes):

```bash
k6 run -e BASE_URL=https://your-endpoint -e LOAD_PROFILE=quick k6_blackfriday.js --summary-export results/summary-quick.json
```

Quick run with explicit endpoint list (recommended when some routes return 403/404):

```bash
k6 run -e BASE_URL=https://your-endpoint -e LOAD_PROFILE=quick -e ENDPOINTS=/ k6_blackfriday.js --summary-export results/summary-quick.json
```

Optional console capture:

```bash
k6 run -e BASE_URL=https://your-endpoint k6_blackfriday.js > results/console.txt
```

## Important Note

The 90k stage is usually not realistic from one local machine.
Use distributed load generators for final campaign evidence.

## Evidence To Archive

1. `results/summary.json`
2. `results/console.txt`
3. Any dashboard screenshot proving latency and error rate
