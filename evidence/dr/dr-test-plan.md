# DR Test Plan

Date: 2026-04-01

Objective: prove DR activation, health validation, and rollback for the GreenLeaf platform.

Scope:
- Secondary region: eu-central-1
- DR ALB: greenleaf-prod-dr-alb
- DR ASG: greenleaf-prod-dr-asg

Success criteria:
- DR capacity scales from 0 to 1
- Health endpoint responds successfully
- DR capacity rolls back to 0
- Timeline and command outputs are archived
