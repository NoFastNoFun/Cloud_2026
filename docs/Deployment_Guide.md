# Guide de Déploiement et d'Exploitation

**Date:** 2026-02-03

---

## Table des Matières

1. [Prérequis](#prérequis)
2. [Configuration Initiale](#configuration-initiale)
3. [Déploiement de l'Infrastructure](#déploiement-de-linfrastructure)
4. [Vérification et Tests](#vérification-et-tests)
5. [Maintenance](#maintenance)
6. [Dépannage](#dépannage)
7. [Optimisations de Coût](#optimisations-de-coût)

---

## Prérequis

### Outils Requis

1. **AWS CLI** (version 2.x)
   ```bash
   # Installation
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   
   # Vérification
   aws --version
   ```

2. **Terraform** (version >= 1.0)
   ```bash
   # Installation (Linux/Mac)
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   
   # Vérification
   terraform version
   ```

3. **Git**
   ```bash
   # Installation
   sudo yum install git -y  # Amazon Linux
   # ou
   sudo apt-get install git -y  # Ubuntu
   ```

### Configuration AWS

1. **Créer un compte AWS** (si nécessaire)

2. **Configurer les credentials AWS**
   ```bash
   aws configure
   # AWS Access Key ID: [VOTRE_ACCESS_KEY]
   # AWS Secret Access Key: [VOTRE_SECRET_KEY]
   # Default region name: eu-west-1
   # Default output format: json
   ```

3. **Vérifier l'accès AWS**
   ```bash
   aws sts get-caller-identity
   ```

4. **Créer une Key Pair (optionnel, pour SSH)**
   ```bash
   aws ec2 create-key-pair --key-name greenleaf-key --query 'KeyMaterial' --output text > ~/.ssh/greenleaf-key.pem
   chmod 400 ~/.ssh/greenleaf-key.pem
   ```

---

## Configuration Initiale

### 1. Cloner le Repository

```bash
git clone https://github.com/NoFastNoFun/Cloud_2026
cd Cloud_2026
```

### 2. Configurer les Variables Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Éditer `terraform.tfvars` avec vos valeurs :

```hcl
# Régions
primary_region = "eu-west-1"
dr_region      = "eu-central-1"
environment    = "prod"

# VPC
vpc_cidr = "10.0.0.0/16"

# EC2 (Optimisé pour réduire les coûts)
instance_type    = "t3.small"     # Réduit de t3.medium pour économiser
min_size         = 1              # Réduit de 2 pour économiser
max_size         = 6              # Peut augmenter selon la charge
desired_capacity = 1              # Réduit de 2 pour économiser

# RDS (Optimisé pour réduire les coûts)
db_instance_class    = "db.t3.small"  # Réduit de db.t3.medium pour économiser
db_allocated_storage = 50             # Réduit de 100GB pour économiser
db_engine_version    = "8.0"
db_name              = "prestashop"
db_username          = "admin"
db_password          = "VOTRE_MOT_DE_PASSE_SECURISE"  # ⚠️ CHANGEZ-MOI

# PrestaShop
prestashop_version      = "8.*"  # Latest PrestaShop 8.x
php_version             = "8.2"
prestashop_admin_email  = "admin@greenleaf.example.com"
prestashop_admin_password = "VOTRE_MOT_DE_PASSE_SECURISE"  # ⚠️ CHANGEZ-MOI
prestashop_domain        = ""  # Will be set to ALB DNS if empty

# Security
allowed_cidr_blocks = ["0.0.0.0/0"]  # Restreindre en production
key_pair_name       = "greenleaf-key"  # Optionnel

# DR (Désactivé par défaut pour réduire les coûts)
enable_dr = false  # Mettre à true si la récupération d'urgence est requise (~$20/mois supplémentaire)
```

**⚠️ IMPORTANT - Variables à modifier obligatoirement :**
- `db_password` : Définir un mot de passe sécurisé pour la base de données
- `prestashop_admin_password` : Définir un mot de passe sécurisé pour l'admin PrestaShop
- `key_pair_name` : Optionnel, mais recommandé pour l'accès SSH

### 3. Initialiser Terraform

```bash
terraform init
```

---

## Déploiement de l'Infrastructure

### ⚠️ Informations Importantes sur la Configuration

Avant de déployer, notez ces points importants :

1. **NAT Instance** : L'infrastructure utilise une NAT Instance (t3.micro) au lieu de NAT Gateways pour réduire les coûts. Cette instance est automatiquement configurée avec IP forwarding et NAT via user-data.

2. **RDS Single-AZ** : La base de données est en Single-AZ (pas de Multi-AZ) pour économiser. En cas de maintenance, il peut y avoir une brève interruption.

3. **1 Instance EC2 Minimum** : Par défaut, seulement 1 instance EC2 est lancée. L'Auto Scaling peut augmenter jusqu'à 6 instances si nécessaire.

4. **DR Région Désactivée** : La région de récupération d'urgence est désactivée par défaut. Activez-la avec `enable_dr = true` si nécessaire.

5. **Variables Obligatoires à Modifier** :
   - `db_password` : DOIT être changé
   - `prestashop_admin_password` : DOIT être changé
   - `key_pair_name` : Recommandé pour l'accès SSH

6. **Coûts Estimés** : ~$75/mois avec la configuration optimisée par défaut.

### Étape 1 : Planification

```bash
terraform plan
```

Vérifier que le plan correspond à vos attentes. Vous devriez voir :
- VPC, Subnets, Internet Gateway, NAT Instance (remplace les NAT Gateways pour réduire les coûts)
- Security Groups
- Application Load Balancer
- Auto Scaling Group (1 instance minimum par défaut)
- RDS Instance (Single-AZ, db.t3.small, 50GB storage)
- S3 Buckets (versioning désactivé pour les assets statiques)
- CloudFront Distribution
- CloudWatch Alarms

### Étape 2 : Déploiement

```bash
terraform apply
```

Terraform va demander confirmation. Tapez `yes` pour continuer.

**Durée estimée : 10-15 minutes**

L'infrastructure se configure automatiquement via user_data. Aucune configuration manuelle n'est nécessaire.

### Étape 3 : Récupérer les Outputs

Une fois le déploiement terminé, récupérer les informations importantes :

```bash
terraform output
```

Noter particulièrement :
- `primary_alb_dns` : URL de l'Application Load Balancer
- `primary_rds_endpoint` : Endpoint de la base de données
- `primary_cloudfront_url` : URL CloudFront

### Étape 4 : Mettre à Jour la Configuration PrestaShop

Si `prestashop_domain` n'était pas défini, mettre à jour :

```bash
# Récupérer l'ALB DNS
ALB_DNS=$(terraform output -raw primary_alb_dns)

# Mettre à jour terraform.tfvars
# prestashop_domain = "${ALB_DNS}"
```

Puis re-appliquer (seulement les ressources concernées seront mises à jour) :

```bash
terraform apply
```

Les instances s'installent et se configurent automatiquement via user_data. Monitorer via :

```bash
# Voir les logs d'installation
aws ssm start-session --target <instance-id>
sudo tail -f /var/log/user-data.log
```

---

## Vérification et Tests

### 1. Vérifier l'Infrastructure

```bash
# Vérifier les instances EC2
aws ec2 describe-instances --filters "Name=tag:Project,Values=GreenLeaf" --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PrivateIpAddress,Tags[?Key==`Name`].Value|[0]]' --output table

# Vérifier l'ALB
aws elbv2 describe-load-balancers --query 'LoadBalancers[*].[LoadBalancerName,DNSName,State.Code]' --output table

# Vérifier RDS
aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,Endpoint.Address,DBInstanceStatus]' --output table

# Vérifier Auto Scaling
aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[*].[AutoScalingGroupName,DesiredCapacity,MinSize,MaxSize]' --output table
```

### 2. Tester l'Application

1. **Accéder à l'ALB**
   ```bash
   ALB_DNS=$(terraform output -raw primary_alb_dns)
   curl http://${ALB_DNS}
   ```

2. **Vérifier le Health Check**
   ```bash
   curl http://${ALB_DNS}/health_check.php
   # Devrait retourner "OK"
   ```

3. **Accéder à l'interface PrestaShop**
   - Ouvrir un navigateur : `http://${ALB_DNS}`
   - Vérifier que la page PrestaShop s'affiche
   - Accéder à l'admin : `http://${ALB_DNS}/admin`

### 3. Tester l'Auto Scaling

```bash
# Obtenir le nom de l'Auto Scaling Group (remplacez greenleaf et prod par vos valeurs si différentes)
ASG_NAME="greenleaf-prod-asg"

# Ou récupérer dynamiquement
ASG_NAME=$(aws autoscaling describe-auto-scaling-groups \
  --query 'AutoScalingGroups[?contains(AutoScalingGroupName, `greenleaf`) && contains(AutoScalingGroupName, `prod`)].AutoScalingGroupName' \
  --output text | head -1)

# Augmenter manuellement la capacité désirée
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name $ASG_NAME \
  --desired-capacity 3

# Vérifier que de nouvelles instances sont lancées
aws ec2 describe-instances --filters "Name=tag:Project,Values=GreenLeaf" --query 'Reservations[*].Instances[*].[InstanceId,State.Name]' --output table

# Remettre à 1 (valeur optimisée par défaut)
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name $ASG_NAME \
  --desired-capacity 1
```

### 4. Vérifier CloudWatch

```bash
# Lister les alarms
aws cloudwatch describe-alarms --alarm-name-prefix greenleaf-prod --query 'MetricAlarms[*].[AlarmName,StateValue]' --output table

# Vérifier les logs
aws logs describe-log-groups --log-group-name-prefix /aws/ec2/greenleaf --query 'logGroups[*].logGroupName' --output table
```

---

## Maintenance

### Mises à Jour de l'Infrastructure

```bash
# Éditer les fichiers .tf ou terraform.tfvars
vim terraform/variables.tf

# Planifier les changements
terraform plan

# Appliquer
terraform apply
```

### Mises à Jour de la Configuration Application

```bash
# Éditer le script user_data
vim terraform/modules/ec2/user_data.sh

# Forcer le remplacement des instances
terraform taint aws_autoscaling_group.prestashop
terraform apply
```

### Sauvegardes

**RDS Backups**
- Automatiques : 3 jours de rétention (réduit de 7 jours pour économiser)
- Performance Insights : Désactivé (pour économiser ~$5/mois)
- Multi-AZ : Désactivé (Single-AZ pour économiser ~$75/mois)
- Snapshots manuels :
  ```bash
  # Obtenir l'identifiant de l'instance RDS (remplacez greenleaf et prod par vos valeurs si différentes)
  DB_IDENTIFIER="greenleaf-prod-db"
  
  # Ou récupérer dynamiquement
  DB_IDENTIFIER=$(aws rds describe-db-instances \
    --query 'DBInstances[?contains(DBInstanceIdentifier, `greenleaf`) && contains(DBInstanceIdentifier, `prod`)].DBInstanceIdentifier' \
    --output text | head -1)
  
  aws rds create-db-snapshot \
    --db-instance-identifier $DB_IDENTIFIER \
    --db-snapshot-identifier ${DB_IDENTIFIER}-snapshot-$(date +%Y%m%d)
  ```

**S3 Backups**
- Les backups sont stockés dans le bucket S3 dédié
- Lifecycle policy : 30 jours de rétention (réduit de 90 jours pour économiser)
- Versions non-courantes : 7 jours de rétention (réduit de 30 jours)

**CloudWatch Logs**
- Rétention : 3 jours (réduit de 7 jours pour économiser)

### Monitoring

**CloudWatch Dashboards**
- Créer un dashboard personnalisé :
  ```bash
  # Via Console AWS ou CLI
  aws cloudwatch put-dashboard \
    --dashboard-name GreenLeaf-Prod \
    --dashboard-body file://dashboard.json
  ```

**Alertes**
- Les alarms CloudWatch envoient des notifications (configurer SNS si nécessaire)

---

## Dépannage

### Problème : Instances EC2 ne démarrent pas

**Vérifications**
```bash
# Vérifier les instances
aws ec2 describe-instances --filters "Name=tag:Project,Values=GreenLeaf"

# Vérifier les logs user-data
# Se connecter via SSM Session Manager
aws ssm start-session --target <instance-id>

# Vérifier les logs
sudo tail -f /var/log/cloud-init-output.log
sudo tail -f /var/log/prestashop-install.log
```

**Solutions**
- Vérifier les Security Groups
- Vérifier les IAM Roles
- Vérifier la connectivité RDS depuis les instances

### Problème : PrestaShop ne s'installe pas

**Vérifications**
```bash
# Se connecter à l'instance
aws ssm start-session --target <instance-id>

# Vérifier PHP
php -v

# Vérifier Composer
composer --version

# Vérifier la connexion à la base de données
mysql -h <RDS_ENDPOINT> -u admin -p

# Vérifier les permissions
ls -la /var/www/prestashop
```

**Solutions**
- Vérifier les credentials RDS (db_host, db_name, db_user, db_password)
- Vérifier les permissions des fichiers PrestaShop (var/, img/, upload/, download/)
- Vérifier que Composer est installé correctement : `composer --version`
- Vérifier que le répertoire /var/www/prestashop existe et appartient à nginx:nginx
- Vérifier les logs d'installation : `/var/log/prestashop-install.log`
- Si l'installation échoue, se connecter à l'instance et exécuter manuellement :
  ```bash
  cd /var/www/prestashop
  sudo -u nginx php install/index_cli.php \
    --domain=<DOMAIN> \
    --db_server=<RDS_ENDPOINT> \
    --db_name=prestashop \
    --db_user=admin \
    --db_password=<PASSWORD> \
    --email=<ADMIN_EMAIL> \
    --password=<ADMIN_PASSWORD> \
    --firstname=Admin \
    --lastname=User \
    --language=en \
    --country=us \
    --newsletter=0 \
    --send_email=0
  ```

### Problème : ALB ne route pas le trafic

**Vérifications**
```bash
# Vérifier les target groups
aws elbv2 describe-target-groups --query 'TargetGroups[*].[TargetGroupName,HealthCheckPath,Targets[*].State]' --output table

# Vérifier la santé des targets
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

**Solutions**
- Vérifier que les instances répondent sur le port 80
- Vérifier le health check path (`/health_check.php`)
- Vérifier les Security Groups (ALB → EC2)

### Problème : RDS inaccessible

**Vérifications**
```bash
# Obtenir l'identifiant de l'instance RDS
DB_IDENTIFIER=$(aws rds describe-db-instances \
  --query 'DBInstances[?contains(DBInstanceIdentifier, `greenleaf`) && contains(DBInstanceIdentifier, `prod`)].DBInstanceIdentifier' \
  --output text | head -1)

# Vérifier le statut RDS
aws rds describe-db-instances --db-instance-identifier $DB_IDENTIFIER

# Vérifier les Security Groups
aws ec2 describe-security-groups --filters "Name=tag:Name,Values=greenleaf-prod-rds-sg"
```

**Solutions**
- Vérifier que le Security Group RDS autorise le trafic depuis EC2
- Vérifier que RDS est dans les subnets privés
- Vérifier les credentials

### Problème : Coûts élevés

**Vérifications**
```bash
# Vérifier les coûts par service (remplacez les dates par la période souhaitée)
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '1 month ago' +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

**Solutions**
- Activer AWS Budgets
- Vérifier les instances inutilisées
- L'infrastructure est déjà optimisée pour les coûts :
  - NAT Instance au lieu de NAT Gateways
  - RDS Single-AZ au lieu de Multi-AZ
  - Instances plus petites (t3.small, db.t3.small)
  - DR région désactivée par défaut
  - Rétentions réduites (backups, logs)
- Utiliser Reserved Instances pour économies supplémentaires (~30%)
- Coût estimé actuel : ~$75/mois

---

## Commandes Utiles

### Terraform

```bash
# Voir l'état
terraform show

# Lister les ressources
terraform state list

# Détruire l'infrastructure (⚠️ ATTENTION)
terraform destroy

# Formater le code
terraform fmt

# Valider la syntaxe
terraform validate
```

### AWS CLI

```bash
# Lister toutes les ressources taguées
aws resourcegroupstaggingapi get-resources --tag-filters Key=Project,Values=GreenLeaf

# Voir les coûts (remplacez les dates par la période souhaitée)
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '1 month ago' +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost
```

### SSM (Accès aux Instances)

```bash
# Se connecter à une instance
aws ssm start-session --target <instance-id>

# Voir les logs de déploiement
sudo cat /var/log/user-data.log

# Vérifier les services
systemctl status nginx php-fpm amazon-cloudwatch-agent
```

---

## Optimisations de Coût

### Configuration Actuelle (Optimisée)

L'infrastructure a été optimisée pour réduire les coûts de **~$370/mois à ~$75/mois** (80% de réduction).

#### Optimisations Implémentées

| Optimisation | Économie | Impact |
|-------------|---------|--------|
| NAT Instance au lieu de NAT Gateways | ~$50/mois | Moins de disponibilité, mais 80% moins cher |
| RDS Single-AZ au lieu de Multi-AZ | ~$75/mois | Pas de failover automatique |
| Instance EC2 t3.small au lieu de t3.medium | ~$15/mois | Moins de CPU/RAM |
| RDS db.t3.small au lieu de db.t3.medium | ~$30/mois | Moins de CPU/RAM |
| 1 instance EC2 minimum au lieu de 2 | ~$15/mois | Pas de redondance au démarrage |
| DR région désactivée | ~$20/mois | Pas de récupération d'urgence |
| Performance Insights désactivé | ~$5/mois | Moins de monitoring détaillé |
| Backup retention 3 jours au lieu de 7 | ~$2/mois | Moins de backups disponibles |
| CloudWatch logs 3 jours au lieu de 7 | ~$2/mois | Moins d'historique de logs |
| S3 backup retention 30 jours au lieu de 90 | ~$1/mois | Moins de backups S3 |
| EBS volumes 20GB au lieu de 30GB | ~$1.60/mois | Moins d'espace disque |
| S3 versioning désactivé | Variable | Pas d'historique de versions |

**Total économisé : ~$295/mois**

### Activer la Haute Disponibilité (Optionnel)

Si vous avez besoin de haute disponibilité, vous pouvez activer ces options (coûts supplémentaires) :

1. **Activer DR Région** :
   ```hcl
   enable_dr = true  # +$20/mois
   ```

2. **Activer RDS Multi-AZ** :
   Modifier `terraform/modules/rds/main.tf` :
   ```hcl
   multi_az = true  # +$75/mois
   ```

3. **Augmenter les Instances EC2** :
   ```hcl
   min_size = 2
   desired_capacity = 2  # +$15/mois
   ```

4. **Utiliser des Instances Plus Grandes** :
   ```hcl
   instance_type = "t3.medium"  # +$15/mois
   db_instance_class = "db.t3.medium"  # +$30/mois
   ```

5. **Activer Performance Insights** :
   Modifier `terraform/modules/rds/main.tf` :
   ```hcl
   performance_insights_enabled = true  # +$5/mois
   ```

### Monitoring des Coûts

**AWS Budgets** (Recommandé) :
```bash
# Créer un budget mensuel de $100 avec alertes
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget file://budget.json
```

**Vérifier les Coûts Actuels** :
```bash
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '1 month ago' +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

### Recommandations Futures

1. **Reserved Instances** : Économie de ~30% si vous vous engagez pour 1 an
2. **Savings Plans** : Économie flexible sur l'utilisation EC2/RDS
3. **Spot Instances** : Pour environnements non-critiques (économie ~70%)
4. **Scheduled Scaling** : Réduire les instances pendant les heures creuses

---

## Support et Ressources

### Documentation

- [Documentation AWS](https://docs.aws.amazon.com/)
- [Documentation Terraform](https://www.terraform.io/docs)
- [Documentation Ansible](https://docs.ansible.com/)
- [Documentation PrestaShop](https://devdocs.prestashop.com/)

### Contacts

Pour toute question ou problème :
- Consulter la documentation du projet
- Vérifier les logs CloudWatch
- Contacter l'équipe DevOps

---

### Activer la Haute Disponibilité (Optionnel)

Si vous avez besoin de haute disponibilité, vous pouvez activer ces options (coûts supplémentaires) :

1. **Activer DR Région** :
   ```hcl
   enable_dr = true  # +$20/mois
   ```

2. **Activer RDS Multi-AZ** :
   Modifier `terraform/modules/rds/main.tf` :
   ```hcl
   multi_az = true  # +$75/mois
   ```

3. **Augmenter les Instances EC2** :
   ```hcl
   min_size = 2
   desired_capacity = 2  # +$15/mois
   ```

4. **Utiliser des Instances Plus Grandes** :
   ```hcl
   instance_type = "t3.medium"  # +$15/mois
   db_instance_class = "db.t3.medium"  # +$30/mois
   ```

5. **Activer Performance Insights** :
   Modifier `terraform/modules/rds/main.tf` :
   ```hcl
   performance_insights_enabled = true  # +$5/mois
   ```

### Monitoring des Coûts

**AWS Budgets** (Recommandé) :
```bash
# Créer un budget mensuel de $100 avec alertes
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget file://budget.json
```

**Vérifier les Coûts Actuels** :
```bash
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '1 month ago' +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

### Recommandations Futures

1. **Reserved Instances** : Économie de ~30% si vous vous engagez pour 1 an
2. **Savings Plans** : Économie flexible sur l'utilisation EC2/RDS
3. **Spot Instances** : Pour environnements non-critiques (économie ~70%)
4. **Scheduled Scaling** : Réduire les instances pendant les heures creuses

---

**Document Version:** 2.0  
**Dernière Mise à Jour:** 2026-01-08  
