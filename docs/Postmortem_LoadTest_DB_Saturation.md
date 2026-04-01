# Post-Mortem - Incident Test de Charge (Saturation BDD)

ID d'Incident : PM-20260325-01
Date : 2026-03-25
Sévérité : SEV2 (Environnement de Pre-Production / Test de Charge)
Commandant d'incident : Équipe Architecture GreenLeaf

## 1. Résumé Exécutif

- **Que s'est-il passé :** Lors de l'exécution de notre campagne de test de charge (tir k6 avec 500 Utilisateurs Virtuels concurrents), la base de données RDS a rejeté les nouvelles connexions. Les serveurs web ont commencé à renvoyer des erreurs HTTP 500 (Internal Server Error) à la chaîne.
- **Impact client :** Nul (0). L'incident s'est produit dans un environnement de test contrôlé (simulation Black Friday).
- **Durée :** 20 minutes avant stabilisation.
- **Statut actuel :** Clos. Problème d'architecture corrigé de manière permanente.

## 2. Chronologie (UTC)

| Heure | Événement |
|---|---|
| 10:00 | Lancement du script de test k6 (k6_blackfriday.js) profil agressif. |
| 10:02 | **Détection** : Déclenchement de l'alarme CloudWatch ALB_Target_5XX et RDS_High_Connections. |
| 10:05 | **Escalade** : Analyse des journaux Nginx/Applicatifs sur l'ASG. Identification de l'erreur SQLSTATE[HY000] [1040] Too many connections. |
| 10:15 | **Action d'atténuation (Mitigation)** : Annulation et arrêt brutal du tir de charge k6. |
| 10:20 | **Rétablissement (Recovery)** : Épuration naturelle des connexions fantômes (Time-out) de la DB. Fin des erreurs 502 sur l'ALB. |
| 10:30 | **Incident clos**. Lancement de l'investigation post-mortem. |

## 3. Impact

- **Impact sur la disponibilité :** 100% d'échec sur les transactions (paniers virtuels) pendant la fenêtre d'incident.
- **Impact sur la latence :** Temps de réponse écroulé, timeout > 10s.
- **Impact sur le taux d'erreur :** Atteinte des 100% d'erreurs 500 et 502 par l'Application Load Balancer lors du pic.
- **Impact sur les revenus :** Aucun (Enviroment Load Test). Si cela s'était produit en production pendant le Black Friday, la perte serait totale.

## 4. Détection

- **Quel signal a détecté le problème en premier ?** Le dashboard d'exécution k6 et les alarmes CloudWatch configurées sur l'ALB.
- **Nom(s) de l'alarme :** wseb-GreenLeaf-ALB-5xx-Count-High, RDS-Connections-Max.
- **L'alerte a-t-elle été assez rapide ?** Oui, comportement identifié en moins de 2 minutes.

## 5. Cause Racine (Root Cause)

- **Cause racine principale :** Épuisement des sockets/threads de connexion de l'instance RDS (db.t3.micro). En raison de l'Auto Scaling Group qui augmentait rapidement le nombre de nœuds EC2 sous la charge, chaque frontend ouvrait des dizaines de requêtes simultanées vers la base de données, saturant la taille limite imposée par AWS sur ce type d'instance.
- **Facteurs contributifs :** Aucune gestion intermédiaire pour réutiliser les connexions ouvertes (Connection Pooling) côté applicatif / infrastructure.
- **Pourquoi le problème n'a-t-il pas été détecté plus tôt :** Les tests fonctionnels à faible trafic (10-20 utilisateurs) ne généraient pas assez de pression réseau pour déclencher cette limite.

## 6. Atténuation et Rétablissement

- **Actions immédiates :** Stoppage de la charge.
- **Ce qui a fonctionné :** Les alarmes CloudWatch ont immédiatement remonté le bon goulot d'étranglement (Nombre de connexions RDS).
- **Ce qui n'a pas fonctionné :** Le système n'a pas pu encaisser la charge des "90k" cibles de manière native dans cette configuration initiale. L'Auto Scaling EC2 était inutile car leBackend (BDD) était la vraie limite.

## 7. Actions Correctives

| Action | Responsable | Date d'échéance | Priorité |
|---|---|---|---|
| **Intégrer AWS RDS Proxy via Terraform** pour multiplexer les connexions. | Équipe DevOps | 2026-03-27 | Critique |
| Restreindre le Security Group RDS pour n'accepter que le Proxy (et non l'EC2). | Équipe Sécu | 2026-03-27 | Haute |
| Relancer le tir de charge à 500 VUs après patch. | QA / Lead k6 | 2026-03-28 | Haute |

## 8. Prévention

- **Améliorations de l'architecture :** C'est cet incident qui a contraint le projet à modifier son infrastructure (DAT) pour inclure un système de multiplexage professionnel (RDS Proxy). 
- **Amélioration de la capacité :** Le test de charge repassé après correction a tenu à 100% de succès, validant formellement l'introduction du correctif.

## 9. Pièces Jointes

- Journal des erreurs EC2 (Too many connections)
- Fichier summary-quick-v1.json (Trace des requêtes échouées avant l'implémentation RDS Proxy).
