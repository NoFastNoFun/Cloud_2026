# Guide de Déploiement Rapide - PrestaShop GreenLeaf

## 📋 Prérequis

Avant de déployer, assurez-vous d'avoir :
- ✅ Terraform appliqué (instances EC2 créées)
- ✅ Ansible installé sur votre machine
- ✅ AWS CLI configuré
- ✅ Clé SSH téléchargée : `~/.ssh/greenleaf-prod-key-fixed.pem`

## 🚀 Méthode 1 : Déploiement Automatique (Recommandé)

Le script PowerShell automatise tout le processus :

```powershell
# Exécutez depuis la racine du projet
.\deploy.ps1
```

Le script va :
1. ✓ Vérifier la clé SSH
2. ✓ Récupérer les informations Terraform (RDS, S3, ALB, etc.)
3. ✓ Trouver l'instance EC2 active
4. ✓ Tester la connexion SSH
5. ✓ Créer l'inventaire Ansible
6. ✓ Proposer de lancer le déploiement

Options disponibles :
```powershell
# Mode verbeux (debug)
.\deploy.ps1 -Verbose

# Pour un environnement spécifique
.\deploy.ps1 -Environment prod
```

## 🔧 Méthode 2 : Déploiement Manuel avec Ansible

Si vous préférez contrôler chaque étape :

### Étape 1 : Préparer l'environnement

```powershell
# Naviguer vers le répertoire Ansible
cd ansible

# Vérifier l'inventaire (créé par deploy.ps1)
cat inventory.ini
```

### Étape 2 : Tester la connectivité

```powershell
# Ping les instances
ansible -i inventory.ini all -m ping

# Vérifier les faits système
ansible -i inventory.ini all -m setup --tree /tmp/facts
```

### Étape 3 : Déployer PrestaShop

```powershell
# Déploiement complet
ansible-playbook -i inventory.ini site.yml

# Déploiement avec mode verbeux (debug)
ansible-playbook -i inventory.ini site.yml -vvv

# Déploiement d'un rôle spécifique seulement
ansible-playbook -i inventory.ini site.yml --tags nginx
ansible-playbook -i inventory.ini site.yml --tags php
ansible-playbook -i inventory.ini site.yml --tags prestashop
```

### Étape 4 : Vérifier le déploiement

```powershell
# Se connecter à l'instance
ssh -i ~/.ssh/greenleaf-prod-key-fixed.pem ec2-user@<INSTANCE_IP>

# Vérifier les services
sudo systemctl status nginx
sudo systemctl status php-fpm
sudo systemctl status amazon-cloudwatch-agent

# Vérifier les logs
sudo tail -f /var/log/nginx/prestashop-access.log
sudo tail -f /var/log/nginx/prestashop-error.log
sudo tail -f /var/log/php-fpm/www-error.log
```

## 📦 Ce qui est déployé

Le playbook Ansible configure :

### 1. **Rôle Common**
- ✓ Mise à jour du système
- ✓ Installation des outils de base
- ✓ Configuration du fuseau horaire
- ✓ Configuration du firewall

### 2. **Rôle Nginx**
- ✓ Installation de Nginx
- ✓ Configuration du virtual host PrestaShop
- ✓ Optimisation des performances
- ✓ Configuration SSL (si certificat disponible)

### 3. **Rôle PHP**
- ✓ Installation de PHP 8.2 et extensions
- ✓ Configuration PHP-FPM
- ✓ Optimisation memory_limit, max_execution_time, etc.
- ✓ Configuration OPcache

### 4. **Rôle MySQL Client**
- ✓ Installation du client MySQL/MariaDB
- ✓ Configuration de la connexion RDS

### 5. **Rôle PrestaShop**
- ✓ Téléchargement de PrestaShop 8.x via Composer
- ✓ Installation automatique via CLI
- ✓ Configuration de la connexion à RDS
- ✓ Configuration de S3 pour les assets statiques
- ✓ Permissions et propriété des fichiers

### 6. **Rôle CloudWatch Agent**
- ✓ Installation de l'agent CloudWatch
- ✓ Configuration des logs (Nginx, PHP, système)
- ✓ Configuration des métriques système

## 🌐 Accès à PrestaShop

Une fois le déploiement terminé :

### Frontend
```
http://<ALB_DNS>/
```

### Administration
```
http://<ALB_DNS>/admin
```

**Identifiants par défaut :**
- Email : `admin@greenleaf.example.com`
- Mot de passe : `NoFastNoFun2026!`

> ⚠️ **Sécurité** : Changez ces identifiants dès la première connexion !

## 🔍 Résolution des problèmes

### Problème : Connexion SSH échoue

```powershell
# Vérifier que le security group autorise SSH
aws ec2 describe-security-groups --region eu-west-1 | findstr "22"

# Obtenir votre IP publique
curl ifconfig.me

# Ajouter votre IP au security group
aws ec2 authorize-security-group-ingress `
  --group-id sg-xxxxx `
  --protocol tcp `
  --port 22 `
  --cidr <YOUR_IP>/32 `
  --region eu-west-1
```

### Problème : Ansible ne trouve pas les instances

```powershell
# Vérifier que les instances sont running
aws ec2 describe-instances `
  --filters "Name=tag:Project,Values=GreenLeaf" "Name=instance-state-name,Values=running" `
  --region eu-west-1

# Rafraîchir l'inventaire
.\deploy.ps1
```

### Problème : Installation PrestaShop échoue

```powershell
# Se connecter à l'instance
ssh -i ~/.ssh/greenleaf-prod-key-fixed.pem ec2-user@<INSTANCE_IP>

# Vérifier les logs
sudo tail -100 /var/log/nginx/prestashop-error.log
sudo tail -100 /var/log/php-fpm/www-error.log

# Vérifier la connexion RDS
mysql -h <DB_HOST> -u admin -p prestashop
```

### Problème : Services ne démarrent pas

```powershell
# Vérifier les services
sudo systemctl status nginx
sudo systemctl status php-fpm

# Vérifier la configuration
sudo nginx -t
sudo php-fpm -t

# Redémarrer les services
sudo systemctl restart nginx
sudo systemctl restart php-fpm
```

## 📊 Monitoring

### Logs CloudWatch

Les logs sont envoyés vers CloudWatch dans les groupes :
- `/aws/ec2/greenleaf/prod/nginx/access`
- `/aws/ec2/greenleaf/prod/nginx/error`
- `/aws/ec2/greenleaf/prod/prestashop/system`

Consultez-les via :
```powershell
aws logs tail /aws/ec2/greenleaf/prod/nginx/access --follow --region eu-west-1
```

### Métriques CloudWatch

Alarmes configurées :
- ✓ CPU élevé (instances EC2)
- ✓ Mémoire élevée (instances EC2)
- ✓ CPU élevé (RDS)
- ✓ Stockage faible (RDS)
- ✓ Connexions élevées (RDS)

## 🔄 Redéploiement

Pour redéployer après des modifications :

```powershell
# Option 1 : Tout redéployer
.\deploy.ps1

# Option 2 : Redéployer un rôle spécifique
cd ansible
ansible-playbook -i inventory.ini site.yml --tags prestashop

# Option 3 : Mode check (dry-run)
ansible-playbook -i inventory.ini site.yml --check
```

## 📚 Ressources

- **Terraform Outputs** : `cd terraform && terraform output`
- **Inventaire Ansible** : `ansible/inventory.ini`
- **Playbook principal** : `ansible/site.yml`
- **Variables** : `ansible/group_vars/all.yml`
- **Documentation complète** : `docs/Deployment_Guide.md`

## ✅ Checklist Post-Déploiement

- [ ] Vérifier que PrestaShop est accessible via l'ALB
- [ ] Se connecter à l'admin et changer les identifiants
- [ ] Configurer le SSL/HTTPS (CloudFront ou ACM)
- [ ] Configurer les DNS pour pointer vers l'ALB
- [ ] Tester l'upload d'images (S3)
- [ ] Vérifier les logs CloudWatch
- [ ] Configurer les sauvegardes RDS
- [ ] Tester la restauration depuis un snapshot
- [ ] Documenter les credentials dans un gestionnaire de mots de passe
- [ ] Configurer les alertes SNS pour les alarmes CloudWatch

---

**Besoin d'aide ?** Consultez le guide complet de déploiement : [docs/Deployment_Guide.md](docs/Deployment_Guide.md)
