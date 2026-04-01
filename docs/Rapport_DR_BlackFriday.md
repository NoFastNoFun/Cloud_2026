# Rapport technique - Drill DR / Failover

Date : 2026-04-01
Projet : GreenLeaf

## 1. Résumé exécutif

Un drill de reprise après sinistre a été exécuté sur la région secondaire `eu-central-1` afin de vérifier la capacité de bascule de l'infrastructure et la validité du plan de continuité. La montée en capacité de l'ASG DR a bien fonctionné, mais le point de santé applicatif exposé par l'ALB DR a retourné une erreur HTTP 502. Le résultat est donc partiellement concluant : l'infrastructure de bascule existe et fonctionne au niveau autoscaling, mais la chaîne applicative DR nécessite une correction avant validation finale.

## 2. Objectif du test

L'objectif du drill était de vérifier trois points :

1. La possibilité de faire passer la capacité DR de 0 à 1.
2. La réponse du point de santé applicatif dans la région secondaire.
3. Le retour à l'état nominal avec une capacité DR ramenée à 0.

## 3. Périmètre et environnement

- Région primaire : `eu-west-1`
- Région DR : `eu-central-1`
- ASG DR : `greenleaf-prod-dr-asg`
- ALB DR : `greenleaf-prod-dr-alb-477238146.eu-central-1.elb.amazonaws.com`
- Date d'exécution : `2026-04-01`

Les preuves associées sont archivées dans [evidence/dr](../evidence/dr/).

## 4. Chronologie d'exécution

| Heure UTC | Événement |
|---|---|
| 2026-04-01T17:02:02Z | Démarrage du drill |
| 2026-04-01T17:02:23Z | Scale-up de l'ASG DR de 0 à 1 |
| 2026-04-01T17:02:57Z | Health check DR testé, retour HTTP 502 |
| 2026-04-01T17:03:30Z | Rollback de l'ASG DR à 0 |

La chronologie détaillée est disponible dans [evidence/dr/dr-timeline.md](../evidence/dr/dr-timeline.md).

## 5. Résultats observés

### 5.1 Montée en capacité

- Avant le test, la capacité désirée était de `0`.
- Après le scale-up, la capacité désirée est passée à `1`.
- Une instance est bien passée à l'état `InService` et `Healthy`.

Preuves : [evidence/dr/dr-before.json](../evidence/dr/dr-before.json), [evidence/dr/dr-after-scaleup.json](../evidence/dr/dr-after-scaleup.json).

### 5.2 Health check applicatif

Le health check effectué sur l'ALB DR a renvoyé une erreur HTTP 502. Cela indique que la bascule réseau et le provisioning EC2 sont opérationnels, mais que l'application ou son bootstrap n'est pas encore correctement prêt dans la région secondaire.

Preuve : [evidence/dr/dr-healthcheck.txt](../evidence/dr/dr-healthcheck.txt).

### 5.3 Rollback

Le retour à l'état nominal a été exécuté avec succès : la capacité désirée a été ramenée à `0` et aucune instance ne restait en service au moment de la capture finale.

Preuve : [evidence/dr/dr-rollback.json](../evidence/dr/dr-rollback.json).

## 6. Analyse technique

Le drill valide la partie infrastructurelle du plan de continuité :

- l'ASG DR peut être activé à la demande ;
- l'instance obtient bien le statut `InService` ;
- la procédure de rollback fonctionne ;
- la télémétrie du drill est archivées.

En revanche, le HTTP 502 observé sur le health check montre un écart sur la couche applicative secondaire. La cause la plus probable est une disponibilité incomplète du bootstrap applicatif, de la configuration d'initialisation ou des dépendances nécessaires au démarrage dans la région DR.

## 7. Impact sur la soutenance

Ce drill apporte une preuve utile pour la soutenance, mais il ne peut pas être présenté comme un failover totalement validé. La bonne lecture est la suivante :

- **Point validé** : l'infrastructure DR existe et la capacité peut être remontée.
- **Point non validé** : le service applicatif DR n'est pas encore sain au niveau du health check.

## 8. Actions correctives recommandées

1. Vérifier le bootstrap utilisateur de l'ASG DR et les dépendances d'installation.
2. Contrôler la santé du target group DR et la logique de readiness de l'application.
3. Relancer un drill après correction et exiger un code HTTP 200 sur `/healthz` ou `/`.
4. Conserver le runbook avec la leçon apprise dans [docs/Runbook_Incident_BlackFriday.md](Runbook_Incident_BlackFriday.md).

## 9. Conclusion

Le test DR a confirmé que le mécanisme de bascule est en place et que le rollback est maîtrisé. Le point bloquant reste la couche applicative dans la région secondaire, qui renvoie HTTP 502 au moment du contrôle. Avant toute validation finale de reprise après sinistre, un correctif de bootstrap ou de readiness doit être apporté puis re-testé.
