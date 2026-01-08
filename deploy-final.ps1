# deploy-final.ps1
# Déploiement PrestaShop “ASG-safe” : boucle sur TOUTES les instances InService, attend qu’elles soient Healthy dans le Target Group, puis déploie.
# Prérequis côté machine : terraform, aws cli, ssh/scp (OpenSSH), clé pem
# Prérequis côté AWS : instances avec IP publique + SG SSH autorisé (ou adapte en SSM)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$KEY_PATH      = "$HOME\.ssh\greenleaf-prod-key-fixed.pem"
$TERRAFORM_DIR = Join-Path $PSScriptRoot "terraform"

Write-Host "=== Récupération des outputs Terraform ===" -ForegroundColor Cyan
Push-Location $TERRAFORM_DIR
$TerraformOutputs = terraform output -json | ConvertFrom-Json
Pop-Location

$REGION        = $TerraformOutputs.primary_region.value
$ALB_DNS       = $TerraformOutputs.primary_alb_dns.value
$DB_HOST       = $TerraformOutputs.primary_rds_address.value
$S3_BUCKET     = $TerraformOutputs.primary_s3_bucket.value
$CLOUDFRONT_URL= $TerraformOutputs.primary_cloudfront_url.value

# Valeurs applicatives (évite de hardcoder en prod, mais ok pour projet)
$DB_NAME  = "prestashop"
$DB_USER  = "admin"
$DB_PASS  = "NoFastNoFun2026!"
$ADMIN_EMAIL = "admin@greenleaf.example.com"
$ADMIN_PASS  = "NoFastNoFun2026!"
$DOMAIN      = $ALB_DNS

# Nommage (aligné sur ton Terraform)
$PROJECT = "greenleaf"
$ENV     = "prod"
$ASG_NAME = "$PROJECT-$ENV-asg"
$TG_NAME  = "$PROJECT-$ENV-tg"

Write-Host "Région: $REGION" -ForegroundColor Green
Write-Host "ALB: $ALB_DNS" -ForegroundColor Green
Write-Host "RDS: $DB_HOST" -ForegroundColor Green
Write-Host "ASG: $ASG_NAME" -ForegroundColor Green
Write-Host "TG:  $TG_NAME" -ForegroundColor Green

Write-Host "`n=== Résolution Target Group ARN ===" -ForegroundColor Cyan
$TARGET_GROUP_ARN = $null
try {
  $TARGET_GROUP_ARN = aws elbv2 describe-target-groups `
    --names $TG_NAME `
    --query "TargetGroups[0].TargetGroupArn" `
    --output text `
    --region $REGION
  if (-not $TARGET_GROUP_ARN -or $TARGET_GROUP_ARN -eq "None") { $TARGET_GROUP_ARN = $null }
} catch {
  $TARGET_GROUP_ARN = $null
}

if ($TARGET_GROUP_ARN) {
  Write-Host "Target Group ARN: $TARGET_GROUP_ARN" -ForegroundColor Green
} else {
  Write-Host "Impossible de récupérer l'ARN du Target Group par son nom. Je continuerai sans 'wait healthy'." -ForegroundColor Yellow
}

Write-Host "`n=== Récupération des instances InService de l'ASG ===" -ForegroundColor Cyan
$AsgInstanceIds = aws autoscaling describe-auto-scaling-groups `
  --auto-scaling-group-names $ASG_NAME `
  --query "AutoScalingGroups[0].Instances[?LifecycleState=='InService'].InstanceId" `
  --output json `
  --region $REGION | ConvertFrom-Json

if (-not $AsgInstanceIds -or $AsgInstanceIds.Count -eq 0) {
  throw "Aucune instance InService dans l'ASG $ASG_NAME"
}

Write-Host "Instances InService: $($AsgInstanceIds -join ', ')" -ForegroundColor Green

Write-Host "`n=== Récupération des IP publiques ===" -ForegroundColor Cyan

$InstancesRaw = aws ec2 describe-instances `
  --instance-ids $AsgInstanceIds `
  --query "Reservations[].Instances[].{InstanceId:InstanceId,PublicIp:PublicIpAddress}" `
  --output json `
  --region $REGION

$InstancesObj = $InstancesRaw | ConvertFrom-Json
$InstancesObj = @($InstancesObj)   # Force un tableau

$InstancesObj = @($InstancesObj | Where-Object { $_.PublicIp -and $_.PublicIp -ne "null" })

if (-not $InstancesObj -or $InstancesObj.Count -eq 0) {
  throw "Aucune IP publique trouvée. Si tu es passé en subnets privés, il faut SSM ou un bastion."
}

Write-Host "Cibles (InstanceId -> IP):" -ForegroundColor Green
$InstancesObj | ForEach-Object {
  Write-Host "  $($_.InstanceId) -> $($_.PublicIp)" -ForegroundColor White
}


function Wait-TargetHealthy {
  param(
    [string]$TargetGroupArn,
    [string]$InstanceId,
    [int]$TimeoutSeconds = 600
  )

  if (-not $TargetGroupArn) { return }

  Write-Host "Attente état Healthy dans Target Group pour $InstanceId ..." -ForegroundColor Cyan
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)

  while ((Get-Date) -lt $deadline) {
    $state = aws elbv2 describe-target-health `
      --target-group-arn $TargetGroupArn `
      --targets Id=$InstanceId `
      --query "TargetHealthDescriptions[0].TargetHealth.State" `
      --output text `
      --region $REGION

    if ($state -eq "healthy") {
      Write-Host "OK: $InstanceId est Healthy" -ForegroundColor Green
      return
    }

    Start-Sleep -Seconds 10
  }

  throw "Timeout: $InstanceId n'est pas devenu healthy dans le Target Group"
}

# Script bash déployé sur chaque instance (LF forcé)
$RemoteScript = @"
#!/usr/bin/env bash
set -euo pipefail

echo "[deploy] start: \$(date)"

DB_HOST="${DB_HOST}"
DB_NAME="${DB_NAME}"
DB_USER="${DB_USER}"
DB_PASS="${DB_PASS}"
ADMIN_EMAIL="${ADMIN_EMAIL}"
ADMIN_PASS="${ADMIN_PASS}"
DOMAIN="${DOMAIN}"

export DEBIAN_FRONTEND=noninteractive

sudo mkdir -p /var/www/html
sudo chown -R nginx:nginx /var/www/html || true

echo "[deploy] install packages"
if command -v dnf >/dev/null 2>&1; then
  sudo dnf -y install nginx git mariadb105 curl unzip php php-fpm php-cli php-common php-mysqlnd php-gd php-xml php-mbstring php-zip php-intl php-opcache php-pdo php-soap
else
  sudo yum -y install nginx git mariadb105 curl unzip php php-fpm php-cli php-common php-mysqlnd php-gd php-xml php-mbstring php-zip php-intl php-opcache php-pdo php-soap
fi

echo "[deploy] ensure composer"
if ! command -v composer >/dev/null 2>&1; then
  curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
  sudo chmod +x /usr/local/bin/composer
fi

echo "[deploy] configure php-fpm"
sudo tee /etc/php-fpm.d/www.conf >/dev/null <<'EOF'
[www]
user = nginx
group = nginx
listen = /run/php-fpm/www.sock
listen.owner = nginx
listen.group = nginx
listen.mode = 0660
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 500
EOF

sudo sed -i 's/^memory_limit = .*/memory_limit = 256M/' /etc/php.ini || true
sudo sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 20M/' /etc/php.ini || true
sudo sed -i 's/^post_max_size = .*/post_max_size = 20M/' /etc/php.ini || true
sudo sed -i 's/^max_execution_time = .*/max_execution_time = 300/' /etc/php.ini || true

sudo systemctl enable php-fpm nginx
sudo systemctl restart php-fpm

echo "[deploy] configure nginx (inclut /healthz)"
sudo tee /etc/nginx/conf.d/prestashop.conf >/dev/null <<EOF
server {
  listen 80;
  server_name _ `${DOMAIN};
  root /var/www/html/prestashop;
  index index.php index.html;

  location = /healthz {
    access_log off;
    return 200 "ok";
    add_header Content-Type text/plain;
  }

  access_log /var/log/nginx/prestashop-access.log;
  error_log  /var/log/nginx/prestashop-error.log;

  location / {
    try_files `$uri `$uri/ /index.php?`$args;
  }

  location ~ \.php`$ {
    fastcgi_pass unix:/run/php-fpm/www.sock;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME `$document_root`$fastcgi_script_name;
    include fastcgi_params;
  }

  location ~ /\. { deny all; }
  location ~ ^/(app|bin|cache|classes|config|controllers|docs|localization|override|src|tests|tools|translations|travis-scripts|vendor)/ { deny all; }
}
EOF

sudo rm -f /etc/nginx/conf.d/default.conf || true
sudo nginx -t
sudo systemctl restart nginx

echo "[deploy] install prestashop (idempotent)"
if [ ! -f /var/www/html/prestashop/index.php ]; then
  cd /var/www/html
  sudo -u nginx composer create-project prestashop/prestashop prestashop "8.*" --no-interaction --prefer-dist
  sudo chown -R nginx:nginx /var/www/html/prestashop
  sudo chmod -R 755 /var/www/html/prestashop
else
  echo "[deploy] prestashop déjà présent, skip composer"
fi

echo "[deploy] prestashop CLI install (si pas déjà installé)"
if [ ! -f /var/www/html/prestashop/config/settings.inc.php ]; then
  if [ -f /var/www/html/prestashop/install/index_cli.php ]; then
    cd /var/www/html/prestashop
    sudo -u nginx php install/index_cli.php \
      --domain="${DOMAIN}" \
      --db_server="${DB_HOST}" \
      --db_name="${DB_NAME}" \
      --db_user="${DB_USER}" \
      --db_password="${DB_PASS}" \
      --email="${ADMIN_EMAIL}" \
      --password="${ADMIN_PASS}" \
      --language=fr \
      --country=fr \
      --prefix=ps_ \
      --firstname=Admin \
      --lastname=GreenLeaf \
      --timezone=Europe/Paris
    sudo -u nginx rm -rf /var/www/html/prestashop/install
  else
    echo "[deploy] install/index_cli.php introuvable"
    exit 1
  fi
else
  echo "[deploy] prestashop déjà configuré (settings.inc.php présent), skip install"
fi

sudo systemctl restart php-fpm
sudo systemctl restart nginx

ADMIN_DIR=`$(cd /var/www/html/prestashop `&`& ls -d admin* 2>/dev/null | head -n 1 `|`| true)

echo "[deploy] done: `$(date)"
echo "[deploy] URL frontend: http://`${DOMAIN}/"
if [ -n "`$ADMIN_DIR" ]; then
  echo "[deploy] URL admin:    http://`${DOMAIN}/`${ADMIN_DIR}/"
else
  echo "[deploy] URL admin:    (dossier admin introuvable, vérifier le contenu de /var/www/html/prestashop)"
fi
"@

# Force LF (évite les CRLF qui cassent bash)
$RemoteScript = $RemoteScript -replace "`r`n", "`n"

# Fichier temporaire local avec encodage UTF-8 sans BOM
$LocalTmp = Join-Path $env:TEMP "greenleaf-deploy.sh"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($LocalTmp, $RemoteScript, $utf8NoBom)


foreach ($inst in $InstancesObj) {
  $INSTANCE_ID = $inst.InstanceId
  $INSTANCE_IP = $inst.PublicIp

  Write-Host "`n=== Déploiement sur $INSTANCE_ID ($INSTANCE_IP) ===" -ForegroundColor Green

  if ($TARGET_GROUP_ARN) {
    Wait-TargetHealthy -TargetGroupArn $TARGET_GROUP_ARN -InstanceId $INSTANCE_ID -TimeoutSeconds 600
  }

  Write-Host "Upload du script..." -ForegroundColor Cyan
  scp -i $KEY_PATH -o StrictHostKeyChecking=no $LocalTmp "ec2-user@${INSTANCE_IP}:/tmp/greenleaf-deploy.sh" | Out-Null

  Write-Host "Exécution..." -ForegroundColor Cyan
  ssh -i $KEY_PATH -o StrictHostKeyChecking=no "ec2-user@${INSTANCE_IP}" "chmod +x /tmp/greenleaf-deploy.sh && sudo /tmp/greenleaf-deploy.sh"

  Write-Host "OK: déploiement terminé sur $INSTANCE_ID" -ForegroundColor Green
}

Remove-Item -Force $LocalTmp -ErrorAction SilentlyContinue

Write-Host "`n=== Déploiement terminé sur toutes les instances InService ===" -ForegroundColor Green
Write-Host "Frontend:   http://$ALB_DNS/" -ForegroundColor White
Write-Host "Healthcheck:http://$ALB_DNS/healthz" -ForegroundColor White
Write-Host "CloudFront: $CLOUDFRONT_URL" -ForegroundColor White
Write-Host "Bucket S3:  $S3_BUCKET" -ForegroundColor White

Write-Host "`nNote importante: tes mots de passe sont en clair dans le script. Pour un rendu propre, mets-les dans SSM Parameter Store (SecureString) et lis-les côté instance." -ForegroundColor Yellow
