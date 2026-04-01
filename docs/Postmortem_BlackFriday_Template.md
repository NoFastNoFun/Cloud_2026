# Modèle de Post-Mortem - Incident Black Friday

ID d'Incident : `BF-YYYYMMDD-XX`
Date : `YYYY-MM-DD`
Sévérité : `SEV1/SEV2/SEV3`
Commandant d'incident : `nom`

## 1. Résumé Exécutif

- Que s'est-il passé :
- Impact client :
- Durée :
- Statut actuel :

## 2. Chronologie (UTC)

| Heure | Événement |
|---|---|
| HH:MM | Détection |
| HH:MM | Escalade |
| HH:MM | Action d'atténuation (Mitigation) |
| HH:MM | Rétablissement (Recovery) |
| HH:MM | Incident clos |

## 3. Impact

- Impact sur la disponibilité :
- Impact sur la latence :
- Impact sur le taux d'erreur :
- Impact sur les revenus / conversions (si disponible) :

## 4. Détection

- Quel signal a détecté le problème en premier ?
- Nom(s) de l'alarme (ou des alarmes) :
- L'alerte a-t-elle été assez rapide ?

## 5. Cause Racine (Root Cause)

- Cause racine principale :
- Facteurs contributifs :
- Pourquoi le problème n'a-t-il pas été détecté plus tôt :

## 6. Atténuation et Rétablissement

- Actions immédiates :
- Actions de rétablissement :
- Ce qui a fonctionné :
- Ce qui n'a pas fonctionné :

## 7. Actions Correctives

| Action | Responsable | Date d'échéance | Priorité |
|---|---|---|---|
| Exemple : ajustement du rate limit WAF | Nom | YYYY-MM-DD | Haute |

## 8. Prévention

- Améliorations de la supervision (monitoring) :
- Améliorations de la capacité et des tests de charge :
- Améliorations de la sécurité :
- Améliorations des processus :

## 9. Pièces Jointes

- Captures d'écran CloudWatch
- Fichiers de résultats k6
- Extraits de logs
- Liens vers les commits / PR (Pull Requests) pertinents
