# Audit d'ecart - Exigences Kubernetes/EKS

Date: 2026-03-30  
Perimetre: repository actuel `Cloud_2026`

## Resume

Les briques Kubernetes/EKS sont maintenant deployees et verifiees en runtime:
- cluster EKS `greenleaf-prod-eks` actif
- nodegroup `greenleaf-prod-primary` actif
- metrics-server operationnel (`kubectl top nodes` OK)
- stack observability Helm deployee (`kube-prometheus-stack`, `jaeger`)
- ressources demo K8s creees (namespace/deployment/service)

## Etat actuel des exigences

| Exigence | Statut | Commentaire | Evidence |
|---|---|---|---|
| EKS cluster (Terraform) | OK | Cluster cree et joignable via `kubectl` | `terraform/modules/eks/`, sortie apply + `kubectl cluster-info` |
| Helm deployment | OK | Releases appliquees dans le cluster | `terraform/providers.tf`, `terraform/modules/k8s-bootstrap/`, `terraform/modules/k8s-observability/` |
| Kubernetes namespaces | OK | Namespaces deployes (`bf-test`, `observability`) | `terraform/modules/k8s-bootstrap/main.tf`, `kubectl get ns` |
| RBAC (roles/bindings/serviceaccounts) | OK | SA/Role/RoleBinding bootstrap appliques | `terraform/modules/k8s-bootstrap/main.tf` |
| HPA | OK | HPA demo applique dans le cluster | `terraform/modules/k8s-autoscaling/main.tf`, `kubectl get hpa -A` |
| VPA | OK | CRD VPA presente + ressource VPA creee apres second apply | `terraform/modules/k8s-autoscaling/main.tf`, `kubectl get crd verticalpodautoscalers.autoscaling.k8s.io` |
| Cluster Autoscaler | OK | IRSA + chart deployes, tags nodegroup en place | `terraform/modules/k8s-autoscaling/`, `terraform/modules/eks/main.tf` |
| Prometheus | OK | `kube-prometheus-stack` deploye | `terraform/modules/k8s-observability/`, `helm list -n observability` |
| Grafana | OK | Service Grafana present dans `observability` | `terraform/modules/k8s-observability/`, `kubectl -n observability get svc` |
| Jaeger / tracing | OK | Chart Jaeger deploye | `terraform/modules/k8s-observability/`, `helm list -n observability` |
| Load testing (k6/Locust) | Partiel | Script et guide prets, rapport reel a archiver | `tests/load/k6_blackfriday.js`, `tests/load/README.md` |
| Seuils perf (p95<2s, erreurs<1%) | Partiel | Thresholds deja codifies, preuves d'execution attendues | `tests/load/k6_blackfriday.js` |
| Security scans Trivy | Partiel | Scripts prets, rapports a produire | `security/scans/run-trivy.ps1`, `security/scans/reports/` |
| Security scans OWASP ZAP | Partiel | Scripts prets, rapports a produire | `security/scans/run-zap.ps1`, `security/scans/reports/` |
| Documentation runbook/postmortem/ADR | OK | Livrables documentaires disponibles | `docs/Runbook_Incident_BlackFriday.md`, `docs/Postmortem_BlackFriday_Template.md`, `docs/ADRs/` |

## Reste a finaliser pour la soutenance

1. Exporter les resultats `k6` dans `tests/load/results/`.
2. Generer et archiver les rapports `Trivy` et `ZAP` dans `security/scans/reports/`.
3. Exporter le dashboard Grafana reel utilise pendant la demo.
4. Prendre 3-4 captures ecran clefs (cluster, hpa/vpa, helm observability, alarmes).
