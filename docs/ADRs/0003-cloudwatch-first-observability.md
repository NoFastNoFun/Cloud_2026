# ADR 0003 - CloudWatch-First Observability

Date: 2026-03-30  
Status: Accepted

## Context

The team needs baseline observability for alarms, logs, and operational dashboards with minimal setup overhead.

## Decision

Adopt CloudWatch as primary observability layer:

1. CloudWatch alarms for infrastructure and app health signals.
2. CloudWatch log groups for nginx and system logs.
3. CloudWatch dashboard for central operator view.
4. SNS integration for alerts.

Grafana can be layered on top when required for deliverables.

## Consequences

Positive:

1. Fast setup and native AWS integration.
2. Operationally consistent alerting path.

Negative:

1. Fewer advanced visualization options than full Grafana stack by default.
2. Tracing remains external unless Jaeger/OpenTelemetry is added.
