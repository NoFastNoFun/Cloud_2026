# Module CloudWatch

Ce module Terraform configure la surveillance complète de votre infrastructure AWS avec CloudWatch.

## 🎯 Fonctionnalités

### Alarmes CloudWatch
- ✅ **EC2/Auto Scaling** : CPU haute/basse, Mémoire haute
- ✅ **RDS** : CPU, Espace disque, Connexions
- ✅ **ALB** : Temps de réponse, Hosts non sains, Erreurs 5XX

### Logs CloudWatch
- ✅ Nginx Access logs
- ✅ Nginx Error logs
- ✅ PrestaShop System logs
- ✅ User Data logs (initialisation EC2)

### SNS Notifications
- ✅ Topic SNS pour toutes les alarmes
- ✅ Abonnements email configurables
- ✅ Support multi-emails

### Dashboard CloudWatch
- ✅ Dashboard centralisé automatique
- ✅ Widgets pour EC2, RDS, ALB
- ✅ Visualisation des logs

## 📋 Prérequis

- ✅ CloudWatch Agent installé sur EC2 (via user_data.sh)
- ✅ IAM Role avec permissions CloudWatch/Logs
- ✅ Auto Scaling Group configuré
- ✅ RDS instance déployée
- ✅ ALB avec target group

## 🚀 Usage

### Configuration de base

```hcl
module "cloudwatch" {
  source = "./modules/cloudwatch"

  project_name         = "greenleaf"
  environment          = "prod"
  region               = "eu-west-1"
  autoscaling_group    = module.ec2.autoscaling_group_name
  rds_instance_id      = module.rds.db_instance_id
  alb_target_group_arn = module.alb.target_group_arn
  alb_arn_suffix       = module.alb.alb_arn_suffix
  
  # Emails pour notifications
  alarm_email_endpoints = [
    "admin@example.com",
    "ops@example.com"
  ]
}
```

### Configuration avancée avec actions personnalisées

```hcl
module "cloudwatch" {
  source = "./modules/cloudwatch"

  project_name         = "greenleaf"
  environment          = "prod"
  region               = "eu-west-1"
  autoscaling_group    = module.ec2.autoscaling_group_name
  rds_instance_id      = module.rds.db_instance_id
  alb_target_group_arn = module.alb.target_group_arn
  alb_arn_suffix       = module.alb.alb_arn_suffix
  
  # Actions personnalisées pour chaque type d'alarme
  high_cpu_alarm_actions = [
    aws_autoscaling_policy.scale_up.arn,
    aws_sns_topic.critical.arn
  ]
  
  low_cpu_alarm_actions = [
    aws_autoscaling_policy.scale_down.arn
  ]
  
  rds_alarm_actions = [
    aws_sns_topic.database_alerts.arn
  ]
  
  alb_alarm_actions = [
    aws_sns_topic.application_alerts.arn
  ]
}
```

## 📥 Inputs

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `project_name` | Nom du projet | `string` | - | ✅ |
| `environment` | Environnement (prod, staging, etc.) | `string` | - | ✅ |
| `region` | Région AWS | `string` | `"eu-west-1"` | ❌ |
| `autoscaling_group` | Nom de l'Auto Scaling Group | `string` | - | ✅ |
| `rds_instance_id` | ID de l'instance RDS | `string` | - | ✅ |
| `alb_target_group_arn` | ARN du target group ALB | `string` | `""` | ❌ |
| `alb_arn_suffix` | ARN suffix de l'ALB | `string` | `""` | ❌ |
| `alarm_email_endpoints` | Liste d'emails pour notifications | `list(string)` | `[]` | ❌ |
| `high_cpu_alarm_actions` | Actions pour alarme CPU haute | `list(string)` | `[]` | ❌ |
| `low_cpu_alarm_actions` | Actions pour alarme CPU basse | `list(string)` | `[]` | ❌ |
| `high_memory_alarm_actions` | Actions pour alarme mémoire haute | `list(string)` | `[]` | ❌ |
| `rds_alarm_actions` | Actions pour alarmes RDS | `list(string)` | `[]` | ❌ |
| `alb_alarm_actions` | Actions pour alarmes ALB | `list(string)` | `[]` | ❌ |

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `alarm_names` | Liste de tous les noms d'alarmes |
| `sns_topic_arn` | ARN du topic SNS |
| `sns_topic_name` | Nom du topic SNS |
| `dashboard_name` | Nom du dashboard CloudWatch |
| `log_group_names` | Map des noms de log groups |

## 🎚️ Seuils d'alarmes par défaut

### EC2 / Auto Scaling
- **High CPU** : > 80% (moyenne sur 2 périodes de 5 min)
- **Low CPU** : < 20% (moyenne sur 2 périodes de 5 min)
- **High Memory** : > 85% (moyenne sur 2 périodes de 5 min)

### RDS
- **High CPU** : > 80% (moyenne sur 2 périodes de 5 min)
- **Free Storage** : < 5 GB (moyenne sur 1 période de 5 min)
- **Connections** : > 400 (moyenne sur 2 périodes de 5 min)

### ALB
- **Response Time** : > 2 secondes (moyenne sur 2 périodes de 5 min)
- **Unhealthy Hosts** : > 0 (moyenne sur 2 périodes de 5 min)
- **5XX Errors** : > 10 (somme sur 2 périodes de 5 min)

## 📊 Métriques personnalisées

Le module s'attend à ce que le CloudWatch Agent envoie ces métriques :

### Namespace : `{project_name}/{environment}`

- `cpu_usage_idle` - CPU inactif (%)
- `cpu_usage_iowait` - CPU en attente I/O (%)
- `cpu_usage_user` - CPU utilisé par applications (%)
- `cpu_usage_system` - CPU utilisé par système (%)
- `mem_used_percent` - Mémoire utilisée (%)
- `disk_used_percent` - Espace disque utilisé (%)

## 🗂️ Log Groups créés

| Log Group | Rétention | Description |
|-----------|-----------|-------------|
| `/aws/ec2/{project}/{env}/nginx/access` | 3 jours | Logs d'accès Nginx |
| `/aws/ec2/{project}/{env}/nginx/error` | 3 jours | Logs d'erreurs Nginx |
| `/aws/ec2/{project}/{env}/prestashop/system` | 3 jours | Logs système PrestaShop |
| `/aws/ec2/{project}/{env}/user-data` | 3 jours | Logs initialisation EC2 |

## 🎨 Dashboard

Le dashboard créé inclut :

1. **EC2 - CPU & Memory** : Graphique combiné
2. **RDS - Performance Metrics** : CPU et connexions
3. **RDS - Storage** : Espace disque
4. **ALB - Performance** : Temps de réponse et requêtes
5. **ALB - Target Health** : Instances saines
6. **Recent Nginx Errors** : 20 dernières erreurs

## 🔔 Notifications SNS

### Comportement par défaut

Si aucune action personnalisée n'est fournie, toutes les alarmes utilisent le topic SNS créé par le module.

### Actions personnalisées

Vous pouvez surcharger les actions pour chaque type d'alarme :

```hcl
high_cpu_alarm_actions = [
  aws_autoscaling_policy.scale_up.arn,  # Auto-scaling
  aws_sns_topic.custom.arn              # Notification personnalisée
]
```

## 🛠️ Personnalisation

### Modifier les seuils d'alarmes

Éditez [main.tf](./main.tf) et ajustez les valeurs `threshold` :

```hcl
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name = "${var.project_name}-${var.environment}-high-cpu"
  threshold  = 90  # Modifier de 80 à 90
  # ...
}
```

### Modifier la rétention des logs

```hcl
resource "aws_cloudwatch_log_group" "nginx_access" {
  name              = "/aws/ec2/${var.project_name}/${var.environment}/nginx/access"
  retention_in_days = 7  # Au lieu de 3
  # ...
}
```

### Ajouter des alarmes

Copiez un bloc d'alarme existant et adaptez-le :

```hcl
resource "aws_cloudwatch_metric_alarm" "custom_alarm" {
  alarm_name          = "${var.project_name}-${var.environment}-custom-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CustomMetric"
  namespace           = "${var.project_name}/${var.environment}"
  period              = 300
  statistic           = "Average"
  threshold           = 100
  alarm_description   = "Custom alarm description"
  alarm_actions       = [aws_sns_topic.cloudwatch_alarms.arn]
}
```

N'oubliez pas d'ajouter le nom de l'alarme aux outputs.

## 🧪 Tests

### Vérifier les alarmes

```bash
# Liste toutes les alarmes
aws cloudwatch describe-alarms \
  --alarm-name-prefix "greenleaf-prod"

# État d'une alarme spécifique
aws cloudwatch describe-alarms \
  --alarm-names "greenleaf-prod-high-cpu"
```

### Tester une alarme

```bash
# Mettre une alarme en état ALARM (test)
aws cloudwatch set-alarm-state \
  --alarm-name "greenleaf-prod-high-cpu" \
  --state-value ALARM \
  --state-reason "Testing alarm"

# Remettre en état OK
aws cloudwatch set-alarm-state \
  --alarm-name "greenleaf-prod-high-cpu" \
  --state-value OK \
  --state-reason "Test completed"
```

### Consulter les logs

```bash
# Liste des log groups
aws logs describe-log-groups \
  --log-group-name-prefix "/aws/ec2/greenleaf"

# Suivre les logs en temps réel
aws logs tail /aws/ec2/greenleaf/prod/nginx/error --follow
```

## 💡 Bonnes pratiques

1. **Emails de notification** : Utilisez une liste de distribution plutôt que des emails individuels
2. **Seuils d'alarmes** : Ajustez selon votre charge réelle après quelques jours de monitoring
3. **Rétention des logs** : 3 jours est suffisant pour le debug, augmentez si nécessaire
4. **Dashboard** : Épinglez le dashboard dans vos favoris AWS Console
5. **Testing** : Testez vos alarmes après déploiement avec `set-alarm-state`

## 📚 Dépendances

### Modules requis
- `vpc` - Pour la configuration réseau
- `ec2` - Pour l'Auto Scaling Group
- `rds` - Pour l'instance de base de données
- `alb` - Pour le load balancer

### IAM Permissions requises

L'IAM role des instances EC2 doit avoir :

```json
{
  "Effect": "Allow",
  "Action": [
    "cloudwatch:PutMetricData",
    "cloudwatch:GetMetricStatistics",
    "cloudwatch:ListMetrics",
    "logs:CreateLogGroup",
    "logs:CreateLogStream",
    "logs:PutLogEvents",
    "logs:DescribeLogStreams"
  ],
  "Resource": "*"
}
```

## 🚨 Troubleshooting

### Les alarmes ne se déclenchent pas

1. Vérifier que les métriques arrivent bien :
```bash
aws cloudwatch get-metric-statistics \
  --namespace "greenleaf/prod" \
  --metric-name mem_used_percent \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T01:00:00Z \
  --period 300 \
  --statistics Average
```

2. Vérifier l'état de l'alarme

### Les logs n'arrivent pas

1. Vérifier CloudWatch Agent sur EC2 :
```bash
sudo systemctl status amazon-cloudwatch-agent
```

2. Consulter les logs de l'agent :
```bash
sudo cat /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log
```

### Les emails ne sont pas reçus

1. Vérifier les abonnements SNS :
```bash
aws sns list-subscriptions-by-topic \
  --topic-arn "arn:aws:sns:eu-west-1:ACCOUNT:greenleaf-prod-cloudwatch-alarms"
```

2. Confirmer les abonnements via l'email reçu

## 📖 Documentation

- [Guide CloudWatch complet](../../docs/CloudWatch_Guide.md)
- [AWS CloudWatch Documentation](https://docs.aws.amazon.com/cloudwatch/)
- [CloudWatch Agent Config](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html)

## 🔄 Version

- **Version** : 1.0
- **Dernière mise à jour** : 2026-02-06
- **Compatible avec** : Terraform >= 1.0
- **Provider AWS** : >= 4.0
