# Rapport hebdomadaire FinOps

Date : 2026-04-01
Projet : GreenLeaf

## 1. Synthèse

La gouvernance FinOps GreenLeaf a ete partiellement consolidee. Ce snapshot se limite volontairement au projet GreenLeaf et n'inclut pas les autres budgets du compte AWS. Les exports Cost Explorer demandes pour le cout par service et la repartition par tag `Project` n'ont pas pu etre extraits automatiquement, car l'utilisateur AWS courant est bloque par une policy explicite `DenyBillingAccess` sur `ce:GetCostAndUsage`. Cette limitation est compatible avec un contexte de compte etudiant, ou les droits Billing sont frequemment restreints.

## 2. Preuves archivées

- [cost-explorer.json](cost-explorer.json) : tentative d'export bloquée par accès Billing.
- [cost-by-tag-project.json](cost-by-tag-project.json) : tentative d'export bloquée par accès Billing.
- [budget-list.json](budget-list.json) : configuration AWS Budgets exportée.

## 3. Budget GreenLeaf

- Aucun budget explicitement nomme GreenLeaf n'a ete trouve dans l'export AWS Budgets.
- Les budgets non GreenLeaf sont hors perimetre de ce rapport et ne sont pas analyses ici.

## 4. Lecture pour GreenLeaf

- Aucun budget nomme GreenLeaf n'a ete trouve dans l'export AWS Budgets actuel.
- La gouvernance couts GreenLeaf n'est donc pas encore reliee a un budget dedie.
- Le suivi cout par service et cout par tag Projet doit etre relance avec un role autorise a interroger Cost Explorer.

## 5. Actions réalisées cette semaine

1. Export des budgets AWS.
2. Tentative d'export Cost Explorer par service.
3. Tentative d'export de la répartition par tag `Project`.
4. Rédaction du rapport de synthèse et archivage des preuves disponibles.

## 6. Action suivante recommandée

Obtenir une autorisation Billing/Cost Explorer temporaire ou faire exécuter les exports depuis un rôle ayant accès à `ce:GetCostAndUsage`, puis remplacer les artefacts d'erreur par les exports réels.

## 7. Statuts theoriques

| Exigence FinOps | Statut theorique | Statut constate | Note |
|---|---|---|---|
| Cout par service (Cost Explorer) | OK | Bloque | Limite de droits Billing sur compte etudiant |
| Cout par tag Project | OK | Bloque | Meme limite de droits Billing |
| Configuration Budgets | OK | OK | Export present |
| Snapshot hebdo | OK | Partiel | Produit avec transparence sur la contrainte d'acces |
