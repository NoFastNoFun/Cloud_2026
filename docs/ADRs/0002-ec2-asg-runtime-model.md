# ADR 0002 - EC2 ASG Runtime Model

Date: 2026-03-30  
Status: Accepted

## Context

The current project implementation runs a PrestaShop workload and requires quick deployability with operational control.

## Decision

Use EC2 Auto Scaling Group behind ALB as runtime model.

Rationale:

1. Simpler stack for team delivery timeline.
2. Easy integration with CloudWatch scaling and alarms.
3. Lower operational complexity for this repository state.

## Consequences

Positive:

1. Straightforward bootstrap and troubleshooting.
2. Predictable cost at baseline.

Negative:

1. Does not directly satisfy EKS-specific expectations in strict Kubernetes grading.
2. Horizontal scaling model is less container-native than EKS.
