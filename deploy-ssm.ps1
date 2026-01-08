# deploy-ssm.ps1
# Déploiement PrestaShop via AWS SSM (sans SSH), compatible ASG
# Prérequis: AWS CLI configuré, terraform installé, accès IAM à SSM SendCommand + GetCommandInvocation + ASG/ELB/EC2 describe.
# Usage: .\deploy-ssm.ps1

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-Command($name) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    throw "Commande manquante: $name"
  }
}

Assert-Command terraform
Assert-Command aws

$TERRAFORM_DIR = Join-Path $PSScriptRoot "terraform"

Write-Host "=== Récupération des outputs Terraform ===" -ForegroundColor Cyan
Push-Location $TERRAFORM_DIR
$tf = terraform output -json | ConvertFrom-Json
Pop-Location

$REGION   = $tf.primary_region.value
$ALB_DNS  = $tf.primary_alb_dns.value
$DB_HOST  = $tf.primary_rds_address.value
$S3_BUCKET= $tf.primary_s3_bucket.value
$CF_URL   = $tf.primary_cloudfront_url.value

$PROJECT = "greenleaf"
$ENV     = "prod"
$ASG_NAME = "$PROJECT-$ENV-asg"
$TG_NAME  = "$PROJECT-$ENV-tg"

# App (à externaliser ensuite dans SSM Parameter Store)
$DB_NAME  = "prestashop"
$DB_USER  = "admin"
$DB_PASS  = "NoFastNoFun2026!"
$ADMIN_EMAIL = "admin@greenleaf.example.com"
$ADMIN_PASS  = "NoFastNoFun2026!"
$DOMAIN      = $ALB_DNS

Write-Host "Region: $REGION" -ForegroundColor Green
Write-Host "ALB:    $ALB_DNS" -ForegroundColor Green
Write-Host "RDS:    $DB_HOST" -ForegroundColor Green
Write-Host "ASG:    $ASG_NAME" -ForegroundColor Green
Write-Host "TG:     $TG_NAME" -ForegroundColor Green

Write-Host "`n=== Résolution Target Group ARN ===" -ForegroundColor Cyan
$TG_ARN = aws elbv2 describe-target-groups `
  --names $TG_NAME `
  --query "TargetGroups[0].TargetGroupArn" `
  --output text `
  --region $REGION

if (-not $TG_ARN -or $TG_ARN -eq "None") { throw "Impossible de récupérer l'ARN du Target Group $TG_NAME" }
Write-Host "Target Group ARN: $TG_ARN" -ForegroundColor Green

Write-Host "`n=== Récupération des instances InService (ASG) ===" -ForegroundColor Cyan
$instanceIds = aws autoscaling describe-auto-scaling-groups `
  --auto-scaling-group-names $ASG_NAME `
  --query "AutoScalingGroups[0].Instances[?LifecycleState=='InService'].InstanceId" `
  --output json `
  --region $REGION | ConvertFrom-Json

if (-not $instanceIds -or $instanceIds.Count -eq 0) { throw "Aucune instance InService dans l'ASG $ASG_NAME" }

Write-Host ("Instances InService: " + ($instanceIds -join ", ")) -ForegroundColor Green

function Wait-TargetHealthy {
  param(
    [string]$TargetGroupArn,
    [string]$InstanceId,
    [int]$TimeoutSeconds = 900
  )
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    $state = aws elbv2 describe-target-health `
      --target-group-arn $TargetGroupArn `
      --targets Id=$InstanceId `
      --query "TargetHealthDescriptions[0].TargetHealth.State" `
      --output text `
      --region $REGION

    if ($state -eq "healthy") {
      Write-Host "OK Healthy: $InstanceId" -ForegroundColor Green
      return
    }
    Write-Host "Attente Healthy ($InstanceId) - état=$state" -ForegroundColor DarkYellow
    Start-Sleep -Seconds 10
  }
  throw "Timeout: $InstanceId n'est pas devenu healthy dans le Target Group"
}

Write-Host "`n=== Attente des instances Healthy dans le Target Group ===" -ForegroundColor Cyan
foreach ($id in $instanceIds) {
  Wait-TargetHealthy -TargetGroupArn $TG_ARN -InstanceId $id -TimeoutSeconds 900
}

# Script bash envoyé par SSM (idempotent)
# Important: on garde /healthz toujours 200 même pendant l'install, pour éviter recyclage ASG.
# Script bash envoyé par SSM (idempotent)
$bash = @'
#!/usr/bin/env bash
set -euo pipefail
exec > >(tee /var/log/greenleaf-deploy.log) 2>&1

echo "[deploy] start: $(date)"

DB_HOST="__DB_HOST__"
DB_NAME="__DB_NAME__"
DB_USER="__DB_USER__"
DB_PASS="__DB_PASS__"
ADMIN_EMAIL="__ADMIN_EMAIL__"
ADMIN_PASS="__ADMIN_PASS__"
DOMAIN="__DOMAIN__"

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

echo "[deploy] configure nginx with /healthz always OK"
sudo mkdir -p /var/www/html
sudo chown -R nginx:nginx /var/www/html || true

sudo tee /etc/nginx/conf.d/prestashop.conf >/dev/null <<'EOF'
server {
  listen 80 default_server;
  server_name _;
  root /var/www/html/prestashop;
  index index.php index.html;

  location = /healthz {
    access_log off;
    add_header Content-Type text/plain;
    return 200 "ok";
  }

  location / {
    try_files $uri $uri/ /index.php?$args;
  }

  location ~ \.php$ {
    fastcgi_pass unix:/run/php-fpm/www.sock;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;
  }

  location ~ /\. { deny all; }
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
  echo "[deploy] prestashop already present"
fi

echo "[deploy] prestashop CLI install (idempotent)"
if [ ! -f /var/www/html/prestashop/config/settings.inc.php ]; then
  cd /var/www/html/prestashop
  if [ -f install/index_cli.php ]; then
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
    echo "[deploy] install/index_cli.php missing"
    exit 1
  fi
else
  echo "[deploy] prestashop already configured"
fi

sudo systemctl restart php-fpm
sudo systemctl restart nginx

echo "[deploy] done: $(date)"
echo "[deploy] frontend: http://${DOMAIN}/"
echo "[deploy] healthz:   http://${DOMAIN}/healthz"
'@

# Injecte les valeurs (remplacement contrôlé)
$bash = $bash.
  Replace("__DB_HOST__", $DB_HOST).
  Replace("__DB_NAME__", $DB_NAME).
  Replace("__DB_USER__", $DB_USER).
  Replace("__DB_PASS__", $DB_PASS).
  Replace("__ADMIN_EMAIL__", $ADMIN_EMAIL).
  Replace("__ADMIN_PASS__", $ADMIN_PASS).
  Replace("__DOMAIN__", $DOMAIN)

# Force LF
$bash = $bash -replace "`r`n", "`n"

Write-Host "`n=== Envoi du déploiement via SSM (AWS-RunShellScript) ===" -ForegroundColor Cyan

# Créer le script complet avec here-document
$fullScript = @"
cat > /tmp/greenleaf-deploy.sh <<'EOFSCRIPT'
$bash
EOFSCRIPT
chmod +x /tmp/greenleaf-deploy.sh
sudo /tmp/greenleaf-deploy.sh
"@

# Créer un fichier JSON temporaire pour les paramètres SSM
$ssmParamsFile = Join-Path $env:TEMP "ssm-params.json"
$ssmParams = @{
  commands = @($fullScript)
} | ConvertTo-Json -Compress
[System.IO.File]::WriteAllText($ssmParamsFile, $ssmParams, [System.Text.Encoding]::UTF8)

# Envoyer la commande SSM avec capture d'erreur
Write-Host "Debug: Envoi de la commande SSM avec $($instanceIds.Count) instances..." -ForegroundColor Yellow
Write-Host "Debug: Fichier params: $ssmParamsFile" -ForegroundColor Yellow

# Envoyer la commande SSM
$awsArgs = @(
  'ssm', 'send-command',
  '--document-name', 'AWS-RunShellScript',
  '--instance-ids'
) + $instanceIds + @(
  '--parameters', "file://$ssmParamsFile",
  '--timeout-seconds', '3600',
  '--region', $REGION,
  '--output', 'json'
)

$payloadRaw = & aws @awsArgs 2>&1
$payloadStr = ($payloadRaw | Out-String).Trim()

Remove-Item -Path $ssmParamsFile -Force -ErrorAction SilentlyContinue

if ($LASTEXITCODE -ne 0) {
  Write-Host "`nAWS CLI error (exit code: $LASTEXITCODE):" -ForegroundColor Red
  Write-Host $payloadStr -ForegroundColor Yellow
  throw "Échec de send-command SSM"
}

# Parser le JSON
try {
  $payload = $payloadStr | ConvertFrom-Json
} catch {
  Write-Host "`nErreur lors du parsing JSON:" -ForegroundColor Red
  Write-Host "Réponse brute: $payloadStr" -ForegroundColor Yellow
  Write-Host "Exception: $($_.Exception.Message)" -ForegroundColor Yellow
  throw "Échec de parsing de la réponse SSM"
}

if (-not $payload -or -not $payload.Command) {
  Write-Host "Erreur: Structure de réponse SSM invalide" -ForegroundColor Red
  Write-Host "Réponse reçue: $($payload | ConvertTo-Json -Depth 3)" -ForegroundColor Yellow
  throw "Échec de send-command SSM - structure invalide"
}

$commandId = $payload.Command.CommandId
Write-Host "SSM CommandId: $commandId" -ForegroundColor Green

function Wait-SSM {
  param([string]$CommandId,[string[]]$InstanceIds,[int]$TimeoutSeconds=3600)
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  $done = @{}
  while ((Get-Date) -lt $deadline) {
    foreach ($id in $InstanceIds) {
      if ($done.ContainsKey($id)) { continue }
      $status = aws ssm get-command-invocation `
        --command-id $CommandId `
        --instance-id $id `
        --query "Status" `
        --output text `
        --region $REGION

      if ($status -in @("Pending","InProgress","Delayed")) {
        continue
      }

      $done[$id] = $status
      Write-Host "Instance $id => $status" -ForegroundColor (if ($status -eq "Success") { "Green" } else { "Red" })
    }

    if ($done.Count -eq $InstanceIds.Count) { return $done }
    Start-Sleep -Seconds 10
  }
  throw "Timeout: exécution SSM trop longue"
}

$results = Wait-SSM -CommandId $commandId -InstanceIds $instanceIds -TimeoutSeconds 3600

Write-Host "`n=== Logs (stdout/stderr) ===" -ForegroundColor Cyan
foreach ($id in $instanceIds) {
  $inv = aws ssm get-command-invocation `
    --command-id $commandId `
    --instance-id $id `
    --output json `
    --region $REGION | ConvertFrom-Json

  Write-Host "`n--- $id : $($inv.Status) ---" -ForegroundColor White
  if ($inv.StandardOutputContent) { Write-Host $inv.StandardOutputContent }
  if ($inv.StandardErrorContent)  { Write-Host $inv.StandardErrorContent -ForegroundColor DarkRed }
}

Write-Host "`n=== Terminé ===" -ForegroundColor Green
Write-Host "Frontend:   http://$ALB_DNS/" -ForegroundColor White
Write-Host "Healthcheck:http://$ALB_DNS/healthz" -ForegroundColor White
Write-Host "CloudFront: $CF_URL" -ForegroundColor White
Write-Host "Bucket S3:  $S3_BUCKET" -ForegroundColor White
