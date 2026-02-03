# Terraform Backend Bootstrap

Ce dossier contient la configuration pour créer les ressources nécessaires au backend Terraform (S3 + DynamoDB).

## Utilisation

### 1. Créer le backend (Une seule fois)

```powershell
cd bootstrap
terraform init
terraform plan
terraform apply
```

### 2. Retourner au projet principal

```powershell
cd ..
terraform init
```

Terraform utilisera maintenant le backend S3 configuré dans `backend.tf`.

## Ressources créées

- **S3 Bucket**: `nf2-terraform-state-bucket`
  - Versioning activé
  - Encryption AES256
  - Accès public bloqué
  - Lifecycle: prevent_destroy

- **DynamoDB Table**: `nf2-terraform-lock`
  - Billing mode: PAY_PER_REQUEST
  - Hash key: LockID
  - Lifecycle: prevent_destroy

## Notes

- L'état de ce bootstrap est stocké **localement** dans `bootstrap/terraform.tfstate`
- ⚠️ **Sauvegardez** le fichier `bootstrap/terraform.tfstate` en lieu sûr
- Les ressources ont `prevent_destroy = true` pour éviter les suppressions accidentelles
