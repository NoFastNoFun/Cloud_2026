# DAT - Document d'Architecture Technique

Projet : GreenLeaf
Contexte : Préparation du Black Friday sur AWS
Périmètre : Infrastructure et opérations uniquement (IaC, sécurité, scalabilité, supervision, FinOps)

## 1. Résumé de l'Architecture

La plateforme est déployée sur AWS à l'aide de modules Terraform :

- Périphérie (Edge) : CloudFront + WAF
- Point d'entrée : Application Load Balancer
- Calcul (Compute) : EC2 Auto Scaling Group
- Base de données : RDS MySQL + RDS Proxy
- Stockage : S3 (assets et sauvegardes)
- Supervision : Alarmes CloudWatch, logs, dashboard, notifications SNS
- DR optionnel : ressources dans une région secondaire (désactivé par défaut)

## 2. Schéma Logique

\\\	ext
Internet
  |
CloudFront + WAF (global)
  |
ALB (eu-west-1)
  |
EC2 ASG (nœuds applicatifs)
  |
RDS Proxy
  |
RDS MySQL

Systèmes annexes :
- S3 (assets statiques)
- S3 (sauvegardes)
- CloudWatch (logs/alarmes/dashboard)
- SNS (notifications d'alarmes)
\\\

## 3. Structure Terraform

- Orchestration principale : 	erraform/main.tf
- Variables partagées : 	erraform/variables.tf
- Fournisseurs et régions : 	erraform/providers.tf
- Backend d'état : 	erraform/backend.tf
- Modules réutilisables :
  - modules/vpc
  - modules/security
  - modules/alb
  - modules/ec2
  - modules/rds
  - modules/s3
  - modules/cloudfront
  - modules/waf
  - modules/waf-alb
  - modules/cloudwatch

## 4. Disponibilité et Scalabilité

- Les sous-réseaux Multi-AZ sont créés à partir des zones de disponibilité sélectionnées.
- L'ALB distribue le trafic vers les instances EC2.
- Les politiques d'Auto Scaling supportent la scalabilité élastique.
- La région de DR peut être activée pour préparer un basculement.

Contrainte connue :
- La stack applicative actuelle est basée sur l'ASG EC2, et non sur Kubernetes/EKS.

## 5. Conception Sécurité

- Segmentation réseau avec des sous-réseaux publics/privés.
- Les groupes de sécurité isolent les niveaux ALB, EC2 et RDS.
- Les règles WAF protègent le point d'entrée et l'ALB (règles managées + limitation de débit).
- Chiffrement au repos sur les ressources de données clés.
- Rôle IAM pour EC2 et permissions de service requises.
- Secrets Manager est utilisé pour l'authentification du proxy RDS.

## 6. Observabilité

- Alarmes CloudWatch :
  - CPU / mémoire EC2
  - CPU / connexions / stockage RDS
  - Temps de réponse ALB / hôtes en échec / erreurs 5xx
- Groupes de logs CloudWatch pour nginx et logs système.
- Dashboard CloudWatch pour une vue consolidée des opérations.
- Sujet SNS pour les notifications d'alerte.

## 7. Stratégie DR (Plan de Reprise d'Activité)

- L'infrastructure de la région secondaire peut être activée avec enable_dr = true.       
- Le cluster DR démarre avec une capacité désirée de zéro pour maîtriser les coûts.
- Le processus de basculement est documenté dans le Runbook.

## 8. Documents Opérationnels

- Guide de déploiement : docs/Deployment_Guide.md
- Guide CloudWatch : docs/CloudWatch_Guide.md
- Runbook d'incident : docs/Runbook_Incident_BlackFriday.md
- Template de Post-mortem : docs/Postmortem_BlackFriday_Template.md
- ADRs : docs/ADRs/

## 9. Risques et Écarts

1. La preuve de l'objectif de performance (90k utilisateurs) n'est pas automatique et doit être démontrée par les rapports de tests de charge.
2. Les scans de sécurité (Trivy/ZAP) nécessitent l'exécution de rapports pour constituer une preuve finale.        
3. Les preuves Grafana/Jaeger dépendent du déploiement de ces outils dans l'environnement d'exécution.   

## 10. Statut des Preuves FinOps

- L'export AWS Budgets est archivé dans evidence/finops/budget-list.json.
- Le snapshot de reporting hebdomadaire est archivé dans evidence/finops/weekly-report.md.  
- L'extraction Cost Explorer par service et par tag Project est actuellement bloquée par la politique de compte concernant ce:GetCostAndUsage.
- Les optimisations de coût au niveau de l'infrastructure en tant que code ("FinOps by design") constituent la démonstration primaire de la gouvernance des coûts dans les limites de l'accès étudiant actuel.
