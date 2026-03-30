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
| HPA | Manquant | Pas de manifest autoscaling K8s | n/a |
| VPA | Manquant | Pas de VPA components/manifests | n/a |
| Cluster Autoscaler | Manquant | Pas de deploiement CAS/IRSA policies dediees | n/a |
| Prometheus | Manquant | Pas de stack kube-prometheus | n/a |
| Grafana | Partiel | Template export JSON present, pas de deploiement K8s prouve | `docs/Grafana_Dashboard_Export.json` |
| Jaeger / tracing | Manquant | Aucun composant tracing deployee | n/a |
| Load testing (k6/Locust) | Partiel | Script k6 et guide presents, execution non prouvee | `tests/load/k6_blackfriday.js` |
| Seuils perf (p95<2s, erreurs<1%) | Partiel | Definis dans k6 thresholds, pas de resultats reels commits | `tests/load/k6_blackfriday.js` |
| Security scans Trivy | Partiel | Scripts/docs presents, rapports absents | `security/scans/` |
| Security scans OWASP ZAP | Partiel | Scripts/docs presents, rapports absents | `security/scans/` |
| Documentation runbook/postmortem/ADR | OK | Livrables documentaires presents | `docs/Runbook_Incident_BlackFriday.md`, `docs/Postmortem_BlackFriday_Template.md`, `docs/ADRs/` |

## Priorites immediates

1. Activer le bootstrap K8s (`enable_k8s_bootstrap=true`) et appliquer namespaces/RBAC/metrics-server.
2. Ajouter HPA/VPA/Cluster Autoscaler.
3. Deployer observabilite K8s (Prometheus/Grafana/Jaeger).
4. Produire les preuves d'execution (k6, Trivy, ZAP, dashboards live).
