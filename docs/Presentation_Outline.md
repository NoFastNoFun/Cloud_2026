# Trame de la Soutenance (15 min + 10 min Q&A)

## 1. Contexte et Objectifs (2 min)

- Contexte Black Friday
- Cibles d'évaluation :
  - Objectif de 90k utilisateurs
  - Latence < 2s
  - Taux d'erreur < 1%

## 2. Architecture (3 min)

- Conception modulaire Terraform
- Parcours du trafic (CloudFront/WAF -> ALB -> ASG -> RDS)
- Approche de Reprise d'Activité (DR)

## 3. Sécurité (2 min)

- **Sécurité via Terraform ("Security as Code")** :
  - *Réseau* : Isolation complète (Sous-réseaux privés pour EC2 et RDS, seul l'ALB est public).
  - *Filtrage* : Security Groups stricts (l'ASG n'accepte que le trafic de l'ALB, le RDS n'accepte que le trafic de l'ASG).
  - *Protection Périphérique* : AWS WAF sur CloudFront (Règles managées AWS, limitation de requêtes anti-DDoS/Bot).
  - *Identité* : Rôles IAM en moindre privilège (Instance Profile EC2).
  - *Données* : Gestion des mots de passe en base via AWS Secrets Manager (aucun secret en clair dans le code) et chiffrement au repos.

## 4. Observabilité (2 min)

- Alarmes, logs et dashboard CloudWatch
- Flux d'alertes et visibilité des incidents

## 5. Performances et Tests de Charge (3 min)

- **Stratégie k6 sur l'infrastructure AWS :**
  - Profil agressif (`quick`) pour simuler un pic d'utilisateurs abrupt.
- **Résultats officiels des tirs de charge Black Friday (voir rapport k6) :**
  - Pic atteint : **500 Utilisateurs Virtuels Simultanés (VUs)** soutenables en continu.
  - Taux de réussite : **100% de succès** (0% d'erreurs sur 139 000 requêtes - objectif métier : < 1% validé).
  - Latence p(95) : **~135 ms** (Objectif métier : < 2s validé avec très grande marge).
  - Débit : **231 requêtes par seconde** très stables.
- **Démonstration Théorique (Prouver les 90k Utilisateurs) :**
  - *Offloading Massif (CDN)* : ~85% du trafic e-commerce (recherches, fiches produits, images) est absorbé en périphérie par le cache CloudFront. Les 90k utilisateurs ne viendront donc jamais saturer le backend en même temps.
  - *Extrapolation Linéaire (ASG)* : Si 1 ou 2 micro-instances EC2 maintiennent facilement 500 VUs intenses sans aucune dégradation de latence, un scale-out horizontal naturel (ASG débridé) absorbera la charge transactionnelle restante.
  - *Protection des Goulots d'étranglement (RDS Proxy)* : La BDD ne tombera pas sous le poids des connexions réseau d'un ASG énorme, car le Proxy absorbe la pression applicative et recycle les connexions MySQL.

## 6. FinOps et Gouvernance (2 min)

- **Approche "FinOps by design" via Terraform** (Compense les restrictions Billing du compte étudiant) :
  - *Compute* : Instances `t3.micro` avec Auto Scaling limité au strict nécessaire (Max : 2).
  - *Base de données* : Rightsizing avec `db.t3.micro` et stockage maîtrisé (50 Go).
  - *Réseau optimisé* : Choix d'une NAT Instance économique au lieu d'une coûteuse NAT Gateway.
  - *Supervision* : Rétention des logs CloudWatch strictement limitée à 3 jours.
  - *Reprise d'Activité (DR)* : Capacité du cluster de secours maintenue à zéro (0) hors basculement.
- Export AWS Budgets et Snapshot hebdomadaire archivés comme preuves documentaires.
- (Préciser oralement que l'export Cost Explorer est bloqué par la politique de l'école/compte étudiant)

## 7. Leçons Apprises et Prochaines Étapes (1 min)

- Ce qui a été amélioré
- Ce qu'il reste à faire
- Roadmap prioritaire

## Supports pour les Questions/Réponses (Q&A)

À garder à portée de main dans les diapositives annexes :

1. Liste des ADRs (Décisions d'Architecture)
2. Extrait du Runbook d'Incident
3. Modèle de Post-mortem
4. Cartographie des modules Terraform
