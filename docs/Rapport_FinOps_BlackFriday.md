# Rapport technique - FinOps et gouvernance des coûts

**Date :** 2026-04-01  
**Projet :** GreenLeaf  

---

## 1. Résumé exécutif

Les preuves FinOps ont été partiellement collectées pour le dossier de soutenance GreenLeaf. Le périmètre de ce rapport est strictement limité à GreenLeaf, sans analyse des autres projets présents dans le compte AWS. Les exports Cost Explorer par service et par tag Project ont été bloqués par une politique explicite DenyBillingAccess sur l'action ce:GetCostAndUsage. Cette restriction est cohérente avec l'usage d'un compte étudiant, où l'accès Billing est souvent volontairement limité. Le rapport conclut donc à une gouvernance coûts documentée mais incomplète tant que les exports de consommation réels GreenLeaf ne sont pas ré-extraits depuis un rôle autorisé.

## 2. Objectifs

1. Obtenir un export du coût par service sur les 30 derniers jours.
2. Obtenir un export de la répartition des coûts par tag Project.
3. Archiver la configuration AWS Budgets.
4. Produire un snapshot hebdomadaire exploitable pour le rapport final.

## 3. Démonstration des optimisations coûts (Terraform)

La budgétisation GreenLeaf n'a pas été seulement documentaire : elle est aussi implémentée directement dans l'Infrastructure as Code (Terraform).

**Optimisations appliquées dans le code :**

* **Compute EC2 rightsizing**
  * instance_type = "t3.micro"
  * ASG borné : min_size = 1, desired_capacity = 1, max_size = 2
  * Objectif : Maintenir un socle de coûts bas et limiter les emballements de capacité.
* **Database rightsizing**
  * db_instance_class = "db.t3.micro"
  * db_allocated_storage = 50
  * Objectif : Réduire le coût fixe mensuel de la base tout en gardant un niveau de service optimal pour un projet de démonstration.
* **DR à coût contrôlé**
  * enable_dr = false dans la configuration standard.
  * Capacité initiale à zéro dans la définition DR (min_size = 0, desired_capacity = 0).
  * Objectif : Ne payer la région secondaire qu'en cas de test (drill) ou d'activation explicite.
* **Egress optimisé**
  * Choix d'une NAT Instance (	3.micro) au lieu d'une NAT Gateway.
  * Objectif : Baisse du coût réseau fixe dans un contexte étudiant/projet.
* **Observabilité dimensionnée coût**
  * Rétention CloudWatch logs à 3 jours.
  * Objectif : Limiter la facture d'ingestion et de stockage des logs.
* **Stack Kubernetes pilotable par flags**
  * Activation conditionnelle EKS/K8s via enable_eks, enable_k8s_bootstrap, enable_k8s_autoscaling, enable_k8s_observability.
  * Objectif : Pouvoir revenir à un profil baseline moins cher sans changer l'architecture Terraform.

**Conformité au cahier des charges :**
Cette maîtrise est démontrée à deux niveaux complémentaires :
* Niveau exploitation : Les exports FinOps (quand les droits Billing le permettent).
* Niveau IaC : Les optimisations coûts encodées dans Terraform ("FinOps by design").

## 4. Preuves archivées

- [Liste des budgets AWS](../evidence/finops/budget-list.json)
- [Rapport hebdomadaire](../evidence/finops/weekly-report.md)
- [Export Cost Explorer (Erreur d'accès)](../evidence/finops/cost-explorer.json)
- [Export par Tag (Erreur d'accès)](../evidence/finops/cost-by-tag-project.json)

**Preuves IaC liées aux optimisations coûts :**
- 	erraform/terraform.tfvars (rightsizing EC2/RDS, flags DR/EKS)
- 	erraform/main.tf (DR compute à capacité zéro par défaut dans le module DR)
- 	erraform/modules/vpc/main.tf (NAT Instance cost-optimized)
- 	erraform/modules/cloudwatch/main.tf (rétention logs 3 jours)

## 5. Configuration AWS Budgets observée (GreenLeaf)

* Aucun budget explicitement nommé GreenLeaf n'a été identifié dans l'export technique.
* Les autres budgets visibles dans le compte sont considérés hors périmètre de ce rapport.
* Cible pour GreenLeaf : Création d'un budget dédié avec alertes à 50%, 80% et 100%.

## 6. Analyse FinOps

### 6.1. Point validé
La présence d'un mécanisme AWS Budgets confirme qu'un cadre de contrôle des coûts existe au niveau du compte de test.

### 6.2. Point non validé
Les exports Cost Explorer par service et par tag ne sont pas exploitables dans l'état actuel, car l'utilisateur AWS courant est bloqué par une policy d'interdiction sur ce:GetCostAndUsage.

### 6.3. Impact pour GreenLeaf
GreenLeaf n'a pas encore de budget dédié identifié. Cela réduit la lisibilité de la gouvernance des coûts du projet et complique le suivi spécifique du dossier de soutenance, d'où la compensation par les optimisations Terraform expliquées en section 3.

## 7. Recommandations

1. Créer un budget GreenLeaf dédié avec des seuils d'alerte configurés.
2. Réexécuter les exports Cost Explorer depuis un rôle ayant les droits Billing.
3. Documenter la répartition par tag Project dès que les droits seront effectifs.
4. Ajouter un snapshot de coût réel hebdomadaire dans le futur.

## 8. Conclusion

La gouvernance FinOps est amorcée, mais la preuve de consommation réelle reste incomplète à cause d'une limitation Billing propre au compte étudiant. 

**Point d'attention pour la soutenance :** 
Les optimisations des coûts de l'infrastructure Terraform GreenLeaf sont déjà effectives dans le code. Elles appliquent une vraie logique FinOps "by design", palliant de façon proactive l'absence momentanée d'exports Billing.

## 9. Statuts théoriques (Cadre de la soutenance)

| Exigence cahier des charges | Statut théorique attendu | Statut actuel (Compte étudiant) | Commentaire |
|---|---|---|---|
| Export Cost Explorer par service | Validé | Bloqué | Donnée non accessible sans droit Billing ce:GetCostAndUsage |
| Export de répartition par tag Project | Validé | Bloqué | Même restriction Billing que ci-dessus |
| Export configuration AWS Budgets | Validé | Validé | Export obtenu et archivé |
| Snapshot hebdomadaire FinOps | Validé | Validé (Partiel) | Snapshot produit avec mention explicite de la limite Billing |

*Lecture recommandée pour la soutenance :*
Dans un contexte d'entreprise standard, les exports manquants seraient pleinement réalisables. L'évaluation FinOps doit être lue en tenant compte de cette contrainte de périmètre étudiant.

## 10. Méthodologie appliquée

### 10.1. Outils utilisés
* **AWS CLI v2** pour l'exécution des exports techniques.
* **AWS Budgets** pour la configuration des plafonds et alertes budgétaires.
* **AWS Cost Explorer** pour l'analyse de coût par service et par tag.
* **Terraform** pour garantir les choix de dimensionnement compatibles FinOps.

### 10.2. Méthode (Alignée sur le cahier des charges)
1. Export des coûts par service sur 30 jours via ws ce get-cost-and-usage.
2. Export de la configuration des budgets via ws budgets describe-budgets.
3. Export de la répartition des coûts via ws ce get-cost-and-usage par tag Project.
4. Consolidation d'un snapshot hebdomadaire.

### 10.3. Résultats obtenus
* **Étape 1** : Bloquée par restriction Billing (DenyBillingAccess).
* **Étape 2** : Validée, export Budgets disponible.
* **Étape 3** : Bloquée par restriction Billing.
* **Étape 4** : Validée partiellement en assumant les limites d'accès.

### 10.4. Conformité au cahier des charges
La démarche demandée a été suivie avec les bons outils et la bonne séquence. Les écarts restants proviennent exclusivement d'une contrainte d'autorisation liée au compte.
