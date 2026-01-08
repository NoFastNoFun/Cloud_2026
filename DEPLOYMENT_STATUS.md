# ✅ Résumé du Déploiement PrestaShop GreenLeaf

## 📊 État Actuel

**Date**: 8 Janvier 2026  
**Statut**: ✅ Déploiement en cours  
**Région**: eu-west-1

---

## 🏗️ Infrastructure Déployée (Terraform)

### Ressources Créées

| Ressource | Détail | Valeur |
|-----------|--------|--------|
| **VPC** | vpc-061ecaa11c6af2fd6 | eu-west-1 |
| **ALB** | Load Balancer principal | greenleaf-prod-alb-813306930.eu-west-1.elb.amazonaws.com |
| **RDS** | Base de données MySQL | greenleaf-prod-db.claw2q6eohy7.eu-west-1.rds.amazonaws.com:3306 |
| **S3** | Bucket pour assets statiques | greenleaf-prod-static-assets-eu-west-1 |
| **CloudFront** | CDN | https://dh9cg450gtl15.cloudfront.net |
| **EC2 PrestaShop** | Instance active | i-06d67caa23d05c090 (52.18.53.237) |
| **EC2 NAT** | Instance NAT | i-0a6697d8a3494e085 (52.215.41.163) |

### CloudWatch Alarms
- ✅ greenleaf-prod-high-cpu
- ✅ greenleaf-prod-low-cpu
- ✅ greenleaf-prod-high-memory
- ✅ greenleaf-prod-rds-high-cpu
- ✅ greenleaf-prod-rds-free-storage
- ✅ greenleaf-prod-rds-connections

---

## 💻 Logiciels Installés sur EC2

### Paquets Système
- ✅ **Amazon Linux 2023**
- ✅ **Nginx 1.28.0**
- ✅ **PHP 8.2.30** avec extensions:
  - php8.2-fpm
  - php8.2-cli
  - php8.2-common
  - php8.2-mysqlnd (MySQL)
  - php8.2-gd (Images)
  - php8.2-xml
  - php8.2-mbstring
  - php8.2-zip
  - php8.2-intl (Internationalisation)
  - php8.2-opcache (Performance)
  - php8.2-pdo
  - php8.2-soap
- ✅ **Composer 2.9.3**
- ✅ **Git**
- ✅ **MariaDB 10.5 Client**

### Application
- 🔄 **PrestaShop 8.2.3** (Installation en cours via Composer)

---

## 🔧 Configuration

### Base de Données
- **Host**: greenleaf-prod-db.claw2q6eohy7.eu-west-1.rds.amazonaws.com
- **Database**: prestashop
- **User**: admin
- **Password**: NoFastNoFun2026!
- **Port**: 3306

### PHP Configuration
```ini
memory_limit = 256M
upload_max_filesize = 20M
post_max_size = 20M
max_execution_time = 300
```

### PHP-FPM Pool (www)
```ini
user = nginx
group = nginx
listen = /run/php-fpm/www.sock
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 500
```

### Nginx Configuration
- **Root**: /var/www/html/prestashop
- **Server Name**: greenleaf-prod-alb-813306930.eu-west-1.elb.amazonaws.com
- **PHP FastCGI**: unix:/run/php-fpm/www.sock
- **Logs**:
  - Access: /var/log/nginx/prestashop-access.log
  - Error: /var/log/nginx/prestashop-error.log

---

## 🚀 Prochaines Étapes

### 1. Finaliser l'installation PrestaShop

Une fois Composer terminé (en cours), exécutez:

```powershell
$KEY_PATH = "$HOME\.ssh\greenleaf-prod-key-fixed.pem"
$INSTANCE_IP = "52.18.53.237"
$DB_HOST = "greenleaf-prod-db.claw2q6eohy7.eu-west-1.rds.amazonaws.com"
$DOMAIN = "greenleaf-prod-alb-813306930.eu-west-1.elb.amazonaws.com"

# Permissions
ssh -i $KEY_PATH -o StrictHostKeyChecking=no ec2-user@$INSTANCE_IP @"
sudo chown -R nginx:nginx /var/www/html/prestashop
sudo chmod -R 755 /var/www/html/prestashop
"@

# Installation PrestaShop
ssh -i $KEY_PATH -o StrictHostKeyChecking=no ec2-user@$INSTANCE_IP @"
cd /var/www/html/prestashop
sudo -u nginx php install/index_cli.php \
  --domain=$DOMAIN \
  --db_server=$DB_HOST \
  --db_name=prestashop \
  --db_user=admin \
  --db_password=NoFastNoFun2026! \
  --email=admin@greenleaf.example.com \
  --password=NoFastNoFun2026! \
  --language=fr \
  --country=fr \
  --prefix=ps_ \
  --firstname=Admin \
  --lastname=GreenLeaf \
  --timezone=Europe/Paris

sudo -u nginx rm -rf /var/www/html/prestashop/install
"@

# Démarrer les services
ssh -i $KEY_PATH -o StrictHostKeyChecking=no ec2-user@$INSTANCE_IP @"
sudo systemctl enable nginx php-fpm
sudo systemctl restart php-fpm
sudo systemctl restart nginx
"@
```

### 2. Vérifier l'accès

```powershell
# Ouvrir dans le navigateur
start http://greenleaf-prod-alb-813306930.eu-west-1.elb.amazonaws.com

# Vérifier les services
ssh -i $KEY_PATH -o StrictHostKeyChecking=no ec2-user@$INSTANCE_IP @"
sudo systemctl status nginx
sudo systemctl status php-fpm
"@
```

---

## 🔑 Identifiants

### Admin PrestaShop
- **Email**: admin@greenleaf.example.com
- **Mot de passe**: NoFastNoFun2026!
- **URL Admin**: http://greenleaf-prod-alb-813306930.eu-west-1.elb.amazonaws.com/admin

⚠️ **IMPORTANT**: Changez ces identifiants après la première connexion !

### Base de Données RDS
- **Host**: greenleaf-prod-db.claw2q6eohy7.eu-west-1.rds.amazonaws.com
- **User**: admin
- **Password**: NoFastNoFun2026!
- **Database**: prestashop

### SSH EC2
- **Clé**: ~/.ssh/greenleaf-prod-key-fixed.pem
- **User**: ec2-user
- **IP**: 52.18.53.237

---

## 📝 Scripts de Déploiement Disponibles

### 1. deploy-final.ps1
Script PowerShell complet qui automatise tout le déploiement:
- Récupère les infos Terraform
- Trouve l'instance active
- Installe tous les packages
- Configure Nginx et PHP
- Installe PrestaShop

**Usage**:
```powershell
.\deploy-final.ps1
```

### 2. deploy.ps1
Script interactif qui prépare l'inventaire Ansible (si vous migrez vers Ansible):
```powershell
.\deploy.ps1
```

---

## 🔍 Vérifications & Monitoring

### Vérifier l'état des instances dans le Target Group
```powershell
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:eu-west-1:622333992348:targetgroup/greenleaf-prod-tg/xxx \
  --region eu-west-1
```

### Voir les logs CloudWatch
```powershell
aws logs tail /aws/ec2/greenleaf/prod/nginx/access --follow --region eu-west-1
aws logs tail /aws/ec2/greenleaf/prod/nginx/error --follow --region eu-west-1
```

### Vérifier la connexion RDS
```powershell
ssh -i ~/.ssh/greenleaf-prod-key-fixed.pem ec2-user@52.18.53.237 \
  "mysql -h greenleaf-prod-db.claw2q6eohy7.eu-west-1.rds.amazonaws.com -u admin -pNoFastNoFun2026! -e 'SHOW DATABASES;'"
```

---

## 🛠️ Dépannage

### Problème: Ansible ne fonctionne pas (Python 3.13)
**Solution**: Utilisez les scripts PowerShell directs (deploy-final.ps1) qui contournent le problème.

### Problème: PHP non installé
**Solution**: PHP 8.2.30 est maintenant installé et fonctionnel.

### Problème: Composer échoue
**Solution**: Utilisez `COMPOSER_ALLOW_SUPERUSER=1` pour éviter les avertissements root.

### Problème: Connexion SSH échoue
**Solution**: Vérifiez que le Security Group autorise SSH (port 22) depuis votre IP:
```powershell
curl ifconfig.me  # Obtenir votre IP
```

### Problème: Site PrestaShop inaccessible
**Vérifications**:
1. Nginx est démarré: `sudo systemctl status nginx`
2. PHP-FPM est démarré: `sudo systemctl status php-fpm`
3. Fichiers PrestaShop existent: `ls -la /var/www/html/prestashop`
4. Permissions correctes: `ls -ld /var/www/html/prestashop`

---

## 📚 Documentation

- **Guide de Déploiement Rapide**: [DEPLOY_QUICK_START.md](DEPLOY_QUICK_START.md)
- **Guide Complet**: [docs/Deployment_Guide.md](docs/Deployment_Guide.md)
- **README**: [readme.md](readme.md)

---

## ✅ Checklist Post-Déploiement

- [x] Infrastructure Terraform appliquée
- [x] Instances EC2 créées et actives
- [x] RDS MySQL créé
- [x] S3 et CloudFront configurés
- [x] Nginx installé et configuré
- [x] PHP 8.2 installé avec extensions
- [x] Composer installé
- [🔄] PrestaShop en cours d'installation
- [ ] PrestaShop configuré avec CLI
- [ ] Services démarrés (Nginx, PHP-FPM)
- [ ] Site accessible via ALB
- [ ] Connexion admin testée
- [ ] Changement des mots de passe par défaut
- [ ] Configuration SSL/HTTPS
- [ ] Configuration DNS
- [ ] Tests de charge
- [ ] Backup RDS configuré
- [ ] Monitoring CloudWatch vérifié

---


