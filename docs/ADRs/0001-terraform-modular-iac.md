# ADR 0001 - Terraform Modular IaC

Date: 2026-03-30  
Status: Accepted

## Context

The project needs reproducible cloud infrastructure with clear ownership boundaries and fast iteration.

## Decision

Use Terraform with:

- Root orchestration (`terraform/main.tf`)
- Domain modules (`vpc`, `security`, `alb`, `ec2`, `rds`, `s3`, `cloudfront`, `waf`, `cloudwatch`)
- Remote backend (`S3 + DynamoDB lock`)

## Consequences

Positive:

1. Reusable components and lower change risk.
2. Clear separation of concerns.
3. Easier review for security and operations.

Negative:

1. More files and module interfaces to maintain.
2. Requires strict variable and output discipline.
