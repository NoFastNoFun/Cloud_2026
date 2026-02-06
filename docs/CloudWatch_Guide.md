# Guide d'utilisation de CloudWatch

## 📊 Vue d'ensemble

CloudWatch est intégré dans votre infrastructure Terraform pour surveiller la santé et les performances de votre application PrestaShop hébergée sur AWS.

## 🎯 Composants surveillés

### 1. **EC2 / Auto Scaling**
- **CPU Utilization** : Alarme si > 80%
- **Memory Usage** : Alarme si > 85%
- **Low CPU** : Alarme si < 20% (pour scale down)

### 2. **RDS (Base de données)**
- **CPU Utilization** : Alarme si > 80%
- **Free Storage Space** : Alarme si < 5 GB
- **Database Connections** : Alarme si > 400 connexions

### 3. **Application Load Balancer (ALB)**
- **Target Response Time** : Alarme si > 2 secondes
- **Unhealthy Hosts** : Alarme dès qu'une instance est non saine
- **5XX Errors** : Alarme si > 10 erreurs sur 5 minutes

### 4. **Logs CloudWatch**
- `/aws/ec2/{project}/{environment}/nginx/access` - Logs d'accès Nginx
- `/aws/ec2/{project}/{environment}/nginx/error` - Logs d'erreurs Nginx
- `/aws/ec2/{project}/{environment}/prestashop/system` - Logs système PrestaShop
- `/aws/ec2/{project}/{environment}/user-data` - Logs d'initialisation EC2

## ⚙️ Configuration

### Variables Terraform

Dans votre fichier `terraform.tfvars`, ajoutez :

```hcl
# Email(s) pour recevoir les notifications d'alarmes
cloudwatch_alarm_email_endpoints = [
  "admin@example.com",
  "ops-team@example.com"
]
```

### Déploiement

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Confirmation des abonnements SNS

Après le déploiement, vous recevrez un email de confirmation pour chaque adresse configurée. **Vous devez confirmer ces abonnements** pour recevoir les notifications.

## 📈 Dashboard CloudWatch

Un dashboard CloudWatch est automatiquement créé : `{project_name}-{environment}-dashboard`

### Accès au Dashboard

1. Connectez-vous à la console AWS
2. Allez dans **CloudWatch** > **Dashboards**
3. Cherchez : `greenleaf-prod-dashboard` (ou votre nom de projet)

### Widgets disponibles

1. **EC2 - CPU & Memory** : Graphique combiné CPU et mémoire
2. **RDS - Performance Metrics** : CPU et connexions DB
3. **RDS - Storage** : Espace disque disponible
4. **ALB - Performance** : Temps de réponse et nombre de requêtes
5. **ALB - Target Health** : Instances saines vs non saines
6. **Recent Nginx Errors** : 20 dernières erreurs Nginx

## 🔔 Notifications

### SNS Topic

Un SNS Topic est créé : `{project_name}-{environment}-cloudwatch-alarms`

### Types de notifications

Vous recevrez des emails lorsque :
- Une alarme passe à l'état **ALARM** (problème détecté)
- Une alarme passe à l'état **OK** (problème résolu)
- Une alarme passe à l'état **INSUFFICIENT_DATA**

### Exemple d'email d'alarme

```
You are receiving this email because your Amazon CloudWatch 
Alarm "greenleaf-prod-high-cpu" in the EU-WEST-1 region has 
entered the ALARM state, because "Threshold Crossed: 2 out of 
the last 2 datapoints [85.5, 88.2] were greater than the 
threshold (80.0)."
```

## 🔍 Consultation des logs

### Via AWS Console

1. Allez dans **CloudWatch** > **Log groups**
2. Sélectionnez le log group désiré
3. Cliquez sur un log stream (instance ID)
4. Consultez les logs

### Via AWS CLI

```bash
# Liste des log groups
aws logs describe-log-groups --log-group-name-prefix "/aws/ec2/greenleaf"

# Récupérer les logs Nginx error
aws logs tail /aws/ec2/greenleaf/prod/nginx/error --follow

# Filtrer les logs
aws logs filter-log-events \
  --log-group-name /aws/ec2/greenleaf/prod/nginx/error \
  --filter-pattern "ERROR" \
  --start-time $(date -d '1 hour ago' +%s)000
```

### Via CloudWatch Insights

```sql
-- Top 10 URLs with most requests
fields @timestamp, request_uri, status
| filter @message like /GET/
| stats count() by request_uri
| sort count desc
| limit 10

-- Errors in the last hour
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100
```

## 📊 Métriques personnalisées

Le CloudWatch Agent collecte automatiquement :

### Métriques CPU
- `cpu_usage_idle` - CPU inactif (%)
- `cpu_usage_iowait` - CPU en attente I/O (%)
- `cpu_usage_user` - CPU utilisé par les applications (%)
- `cpu_usage_system` - CPU utilisé par le système (%)

### Métriques Mémoire
- `mem_used_percent` - Mémoire utilisée (%)

### Métriques Disque
- `disk_used_percent` - Espace disque utilisé (%)

### Namespace

Toutes les métriques personnalisées sont dans le namespace : `{project_name}/{environment}`

Exemple : `greenleaf/prod`

## 🛠️ Personnalisation des alarmes

### Modifier les seuils

Dans `terraform/modules/cloudwatch/main.tf`, vous pouvez ajuster :

```hcl
# Exemple : Modifier le seuil CPU de 80% à 90%
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-high-cpu"
  threshold           = 90  # <-- Modifier ici
  # ...
}
```

### Ajouter des actions personnalisées

```hcl
# Dans terraform/main.tf
module "primary_cloudwatch" {
  source = "./modules/cloudwatch"
  
  # ...
  
  # Ajouter une policy de scaling automatique
  high_cpu_alarm_actions = [
    aws_autoscaling_policy.scale_up.arn
  ]
  
  low_cpu_alarm_actions = [
    aws_autoscaling_policy.scale_down.arn
  ]
}
```

## 🌍 Région DR (Disaster Recovery)

Si `enable_dr = true`, CloudWatch est automatiquement déployé dans la région DR avec :
- Toutes les mêmes alarmes
- Dashboard séparé
- SNS topic dédié

Accès via la console AWS dans la région DR configurée.

## 🚨 Résolution de problèmes

### Les logs n'apparaissent pas

1. Vérifier que CloudWatch Agent est actif :
```bash
sudo systemctl status amazon-cloudwatch-agent
```

2. Consulter les logs de l'agent :
```bash
sudo tail -f /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log
```

3. Vérifier les permissions IAM de l'instance EC2

### Les notifications ne sont pas reçues

1. Vérifier que vous avez confirmé l'abonnement SNS par email
2. Vérifier dans SNS > Topics > Subscriptions
3. Confirmer que l'alarme est bien en état **ALARM**

### Les métriques personnalisées n'apparaissent pas

1. Vérifier la configuration CloudWatch Agent :
```bash
sudo cat /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
```

2. Redémarrer l'agent :
```bash
sudo systemctl restart amazon-cloudwatch-agent
```

3. Consulter les métriques dans la console :
   - CloudWatch > Metrics > Custom Namespaces > `{project_name}/{environment}`

## 💰 Coûts

### Estimation mensuelle (région unique)

- **Log Ingestion** : ~5 GB/mois = $2.50
- **Log Storage** : Rétention 3 jours = $0.15
- **Métriques personnalisées** : 5 métriques = $1.50
- **Dashboard** : 1 dashboard = $3.00
- **Alarmes** : 9 alarmes standards = $0.00 (10 premières gratuites)

**Total estimé** : ~$7-10/mois par région

### Optimisation des coûts

1. **Réduire la rétention des logs** :
```hcl
resource "aws_cloudwatch_log_group" "nginx_access" {
  retention_in_days = 1  # Au lieu de 3
}
```

2. **Filtrer les logs avant envoi** (dans user_data.sh)
3. **Utiliser des métriques moins fréquentes** (period plus long)

## 📚 Ressources supplémentaires

- [Documentation AWS CloudWatch](https://docs.aws.amazon.com/cloudwatch/)
- [CloudWatch Agent Configuration](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html)
- [CloudWatch Pricing](https://aws.amazon.com/cloudwatch/pricing/)
- [Best Practices for CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Best_Practice_Recommended_Alarms_AWS_Services.html)

## 🆘 Support

Pour toute question ou problème, consultez :
1. Le [Deployment Guide](./Deployment_Guide.md)
2. Les logs CloudWatch
3. Le dashboard CloudWatch
4. La documentation AWS
