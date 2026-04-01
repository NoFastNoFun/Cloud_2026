# Runbook d'Incident - Black Friday

Ce runbook est destiné à la gestion des incidents en direct pendant la simulation du pic de trafic.

## 1. Rôles

- **Commandant d'incident (Incident Commander)** : prend les décisions et fixe les priorités.
- **Responsable Ops (Ops Lead)** : exécute les actions sur l'infrastructure.
- **Responsable App (App Lead)** : effectue les vérifications applicatives.
- **Scribe** : tient le journal chronologique ("timeline") et trace les décisions.
- **Communication** : informe les parties prenantes de l'état d'avancement.

## 2. Niveaux de Sévérité

- \SEV1\ : interruption majeure ou impact fort sur l'activité métier.
- \SEV2\ : service dégradé mais solution de contournement (workaround) disponible.
- \SEV3\ : problème mineur avec un impact limité.

## 3. Checklist des 10 Premières Minutes

1. Déclarer la sévérité et ouvrir un canal d'incident.
2. Noter l'heure de début et le premier symptôme.
3. Vérifier la santé de l'ALB, le taux d'erreurs 5xx, et le temps de réponse.
4. Vérifier le nombre d'instances désirées/en service dans l'ASG EC2.
5. Vérifier le CPU, les connexions et l'espace de stockage de la base RDS.
6. Confirmer si le nombre de blocages WAF est anormal.

## 4. Scénarios (Playbooks)

### A. Forte Latence (> 2s en p95)

1. Valider la métrique CloudWatch \TargetResponseTime\.
2. Confirmer l'éventuelle saturation (CPU/mémoire) sur les EC2.
3. Augmenter la capacité de l'ASG si nécessaire.
4. Vérifier les connexions à la base de données et la pression des requêtes lentes.
5. Vérifier s'il y a eu un déploiement récent ou une régression.

### B. Pic du Taux d'Erreurs (> 1%)

1. Vérifier \HTTPCode_Target_5XX_Count\ sur l'ALB.
2. Inspecter le groupe de logs \/aws/ec2/.../nginx/error\.
3. Vérifier l'état de santé des instances (health checks) dans le Target Group.
4. Drainer les instances défaillantes et déclencher un remplacement si nécessaire.

### C. Cibles Non Saines (Unhealthy Targets)

1. Valider le endpoint \/healthz\ directement sur l'instance et via l'ALB.
2. Vérifier les logs d'amorçage (user-data/bootstrap).
3. Confirmer que les services applicatifs (ex: Nginx, PHP-FPM, Node...) sont en cours d'exécution.
4. Remplacer les nœuds défaillants via l'ASG.

### D. Saturation de la Base de Données

1. Vérifier le CPU RDS et les \DatabaseConnections\.
2. Vérifier l'état du RDS Proxy.
3. Réduire la pression en ajoutant des nœuds applicatifs ou en limitant le trafic abusif.
4. Si indispensable, augmentation verticale (scale-up) temporaire de la base de données.

### E. Attaque Suspectée / Vague de Bots

1. Vérifier les requêtes WAF échantillonnées (sampled requests) et le nombre de blocages.
2. Durcir la règle de limitation de débit (rate limit) WAF si l'attaque est confirmée.
3. Conserver des notes d'incident pour le post-mortem et l'ajustement futur de la règle.

## 5. Procédure de Basculement (si DR activé)

1. Confirmer que l'instabilité de la région principale dépasse l'objectif de RTO (Recovery Objective).
2. Augmenter l'ASG de DR (de zéro au minimum opérationnel).
3. Valider l'état de santé de l'ALB DR.
4. Mettre à jour la stratégie de routage du trafic (DNS/Route53).
5. Annoncer le statut et surveiller les erreurs et la latence.

## 6. Critères de Fin d'Incident

Clôturer l'incident uniquement lorsque :

1. La latence p95 est de nouveau inférieure à 2s.
2. Le taux d'erreur est retombé sous les 1%.
3. Il n'y a plus aucune alarme critique active.
4. Une communication officielle de rétablissement (avec horodatage) a été envoyée.

## 7. Actions Post-Incident (Post-Mortem)

1. Remplir le modèle (template) de post-mortem.
2. Ouvrir des tickets d'actions correctives avec un responsable et une date d'échéance.
3. Mettre à jour ce runbook si des lacunes dans le processus ont été identifiées.

## 8. Leçons Apprises lors des Exercices de DR (DR Drill)

- La capacité DR peut être scalée de 0 à 1 dans eu-central-1, et l'ASG y atteint bien l'état \InService\.
- Lors du dernier exercice, le contrôle de santé (health check) de l'ALB DR a renvoyé une erreur HTTP 502, indiquant un problème de préparation applicative ou d'amorçage, plutôt qu'un problème d'autoscaling.
- Avant de valider un basculement de production officiel, s'assurer de valider entièrement le script \user-data\, la santé du Target Group et la réponse du endpoint applicatif sur la seconde région.
