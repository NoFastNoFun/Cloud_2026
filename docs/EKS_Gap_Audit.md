# Audit d'ecart - Exigences Kubernetes/EKS

Date: 2026-03-30  
Perimetre: repository actuel `Cloud_2026`

## Resume

Le projet actuel est majoritairement EC2/ALB/RDS.  
Les exigences Kubernetes/EKS sont partiellement couvertes au niveau preparation documentaire, mais pas encore au niveau execution runtime.

## Checklist manquant / partiel / ok

| Exigence | Statut | Commentaire | Evidence |
|---|---|---|---|
| EKS cluster (Terraform) | Partiel | Module EKS ajoute dans cette iteration, pas encore deploiement prouve | `terraform/modules/eks/`, `terraform/main.tf` |
| Helm deployment | Partiel | Provider Helm et release metrics-server implementes, non appliques dans l'environnement | `terraform/providers.tf`, `terraform/modules/k8s-bootstrap/` |
| Kubernetes namespaces | Partiel | Terraform namespace bootstrap implementes, non appliques dans l'environnement | `terraform/modules/k8s-bootstrap/main.tf` |
| RBAC (roles/bindings/serviceaccounts) | Partiel | Role/RoleBinding/ServiceAccount bootstrap implementes, non appliques dans l'environnement | `terraform/modules/k8s-bootstrap/main.tf` |
| HPA | Partiel | HPA demo Terraform implemente, execution en environnement a valider | `terraform/modules/k8s-autoscaling/main.tf` |
| VPA | Partiel | Deploiement VPA + resource demo implementes, execution en environnement a valider | `terraform/modules/k8s-autoscaling/main.tf` |
| Cluster Autoscaler | Partiel | IRSA + Helm + tags ASG implementes, execution en environnement a valider | `terraform/modules/k8s-autoscaling/`, `terraform/modules/eks/main.tf` |
| Prometheus | Partiel | Module Helm kube-prometheus-stack implemente, execution en environnement a valider | `terraform/modules/k8s-observability/` |
| Grafana | Partiel | Deploiement via kube-prometheus-stack implemente + export template repo | `terraform/modules/k8s-observability/`, `docs/Grafana_Dashboard_Export.json` |
| Jaeger / tracing | Partiel | Deploiement Helm Jaeger implemente, execution en environnement a valider | `terraform/modules/k8s-observability/` |
| Load testing (k6/Locust) | Partiel | Script k6 et guide presents, execution non prouvee | `tests/load/k6_blackfriday.js` |
| Seuils perf (p95<2s, erreurs<1%) | Partiel | Definis dans k6 thresholds, pas de resultats reels commits | `tests/load/k6_blackfriday.js` |
| Security scans Trivy | Partiel | Scripts/docs presents, rapports absents | `security/scans/` |
| Security scans OWASP ZAP | Partiel | Scripts/docs presents, rapports absents | `security/scans/` |
| Documentation runbook/postmortem/ADR | OK | Livrables documentaires presents | `docs/Runbook_Incident_BlackFriday.md`, `docs/Postmortem_BlackFriday_Template.md`, `docs/ADRs/` |

## Priorites immediates

1. Activer le bootstrap K8s (`enable_k8s_bootstrap=true`) et appliquer namespaces/RBAC/metrics-server.
2. Activer `enable_k8s_autoscaling=true` et verifier HPA/VPA/Cluster Autoscaler en live.
3. Activer `enable_k8s_observability=true` et verifier Prometheus/Grafana/Jaeger en live.
4. Produire les preuves d'execution (k6, Trivy, ZAP, dashboards live).
