#!/bin/bash
set -euo pipefail

# ============================================================
# KERNEL TUNING - Optimisation pour 9000+ connexions simultanees
# Calcul : 9000 conn x ~10 fd/conn = 90000 fd necessaires
# ============================================================

# --- Parametres sysctl (fichier dedie, modulaire, rollback propre) ---
cat > /etc/sysctl.d/99-high-concurrency.conf <<'SYSCTL'
# --- File Descriptors ---
fs.file-max = 100000

# --- TCP Connection Queue ---
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 5000

# --- TCP TIME_WAIT ---
net.ipv4.tcp_max_tw_buckets = 1440000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15

# --- Ports ephemeres ---
net.ipv4.ip_local_port_range = 1024 65535

# --- TCP Keepalive (detection connexions mortes) ---
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 5

# --- Memoire virtuelle ---
vm.swappiness = 10
SYSCTL

sysctl --system

# --- Limites file descriptors (fichier dedie) ---
cat > /etc/security/limits.d/99-high-concurrency.conf <<'LIMITS'
* soft nofile 100000
* hard nofile 100000
nginx soft nofile 100000
nginx hard nofile 100000
LIMITS

# --- Overrides systemd pour Nginx et PHP-FPM ---
# systemd ignore limits.conf : sans ces overrides, les services restent a 1024 fd
mkdir -p /etc/systemd/system/nginx.service.d
cat > /etc/systemd/system/nginx.service.d/limits.conf <<'SYSD'
[Service]
LimitNOFILE=100000
SYSD

mkdir -p /etc/systemd/system/php-fpm.service.d
cat > /etc/systemd/system/php-fpm.service.d/limits.conf <<'SYSD'
[Service]
LimitNOFILE=100000
SYSD

systemctl daemon-reload

# --- Verification du tuning (log consultable via CloudWatch ou SSH) ---
{
  echo "=== Kernel Tuning Verification - $(date) ==="
  echo "--- sysctl values ---"
  sysctl fs.file-max \
         net.core.somaxconn \
         net.core.netdev_max_backlog \
         net.ipv4.tcp_max_tw_buckets \
         net.ipv4.tcp_tw_reuse \
         net.ipv4.tcp_fin_timeout \
         net.ipv4.ip_local_port_range \
         net.ipv4.tcp_keepalive_time \
         net.ipv4.tcp_keepalive_intvl \
         net.ipv4.tcp_keepalive_probes \
         vm.swappiness
  echo "--- ulimits (root context) ---"
  ulimit -n
} >> /var/log/kernel-tuning-verification.log 2>&1

# ============================================================
# FIN KERNEL TUNING
# ============================================================

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "=========================================="
echo "Starting user-data script at $(date)"
echo "=========================================="

# Variables from Terraform
DB_ENDPOINT="${db_endpoint}"
DB_NAME="${db_name}"
DB_USERNAME="${db_username}"
DB_PASSWORD="${db_password}"
S3_BUCKET="${s3_bucket_name}"
CLOUDFRONT_URL="${cloudfront_url}"
PRESTASHOP_VERSION="${prestashop_version}"
PHP_VERSION="${php_version}"
ADMIN_EMAIL="${prestashop_admin_email}"
ADMIN_PASSWORD="${prestashop_admin_password}"
DOMAIN="${prestashop_domain}"
PROJECT_NAME="${project_name}"
ENVIRONMENT="${environment}"
REGION="${region}"

PRESTASHOP_DIR="/var/www/prestashop"
PHP_MEMORY_LIMIT="512M"
PHP_MAX_EXECUTION_TIME="300"
PHP_MAX_INPUT_VARS="5000"

# ========================================
# 1. SYSTEM SETUP
# ========================================
echo "[1/8] Installing system packages..."

# Fix curl-minimal conflict on Amazon Linux 2023
yum remove -y curl-minimal || true

yum update -y
yum install -y \
    git wget unzip curl vim htop \
    nginx \
    php php-fpm php-cli php-common php-gd php-intl php-mbstring \
    php-mysqlnd php-opcache php-xml php-zip php-json php-curl \
    php-bcmath php-soap \
    mariadb105 \
    amazon-cloudwatch-agent \
    amazon-ssm-agent

# Set timezone
timedatectl set-timezone UTC

# Enable SSM agent
systemctl enable --now amazon-ssm-agent

# ========================================
# 2. PHP CONFIGURATION
# ========================================
echo "[2/8] Configuring PHP..."

# Configure PHP settings
cat > /etc/php.d/99-prestashop.ini <<EOF
memory_limit = $PHP_MEMORY_LIMIT
max_execution_time = $PHP_MAX_EXECUTION_TIME
max_input_vars = $PHP_MAX_INPUT_VARS
upload_max_filesize = 64M
post_max_size = 64M

opcache.enable=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=20000
opcache.revalidate_freq=2
opcache.fast_shutdown=1
EOF

# Configure PHP-FPM
cat > /etc/php-fpm.d/www.conf <<EOF
[www]
user = nginx
group = nginx
listen = 127.0.0.1:9000
listen.owner = nginx
listen.group = nginx
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 500
EOF

systemctl enable php-fpm
systemctl start php-fpm

# ========================================
# 3. NGINX CONFIGURATION
# ========================================
echo "[3/8] Configuring Nginx..."

# Remove default config
rm -f /etc/nginx/conf.d/default.conf

# Create PrestaShop Nginx configuration
cat > /etc/nginx/conf.d/prestashop.conf <<'NGINXEOF'
upstream fastcgi_backend {
    server 127.0.0.1:9000;
}

server {
    listen 80;
    server_name _;

    root /var/www/prestashop;
    index index.php index.html;
    charset UTF-8;

    # Health check endpoint
    location = /healthz {
        access_log off;
        return 200 "ok";
        add_header Content-Type text/plain;
    }

    # PHP entry point for main application
    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_pass fastcgi_backend;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_read_timeout 300;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 4 256k;
        fastcgi_busy_buffers_size 256k;
    }

    # PrestaShop friendly URLs
    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    # Deny access to sensitive files
    location ~ ^/(app|bin|cache|classes|config|controllers|docs|localization|override|src|tests|tools|translations|upload|var|vendor)/ {
        deny all;
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Static files caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # Gzip compression
    gzip on;
    gzip_disable "msie6";
    gzip_comp_level 6;
    gzip_min_length 1100;
    gzip_buffers 16 8k;
    gzip_proxied any;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/rss+xml
        font/truetype
        font/opentype
        application/vnd.ms-fontobject
        image/svg+xml;
}
NGINXEOF

nginx -t
systemctl enable nginx
systemctl start nginx

# ========================================
# 4. INSTALL COMPOSER
# ========================================
echo "[4/8] Installing Composer..."
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer

# ========================================
# 5. INSTALL PRESTASHOP
# ========================================
echo "[5/8] Installing PrestaShop..."

# Create PrestaShop directory
mkdir -p $PRESTASHOP_DIR
chown -R nginx:nginx $PRESTASHOP_DIR

# Install PrestaShop via Composer
cd /tmp
sudo -u nginx COMPOSER_HOME=/tmp/composer /usr/local/bin/composer create-project \
    prestashop/prestashop $PRESTASHOP_DIR "$PRESTASHOP_VERSION" \
    --no-dev --prefer-dist --no-interaction || {
    echo "WARNING: Composer installation failed. Creating placeholder..."
    mkdir -p $PRESTASHOP_DIR
    cat > $PRESTASHOP_DIR/index.php <<'PHPEOF'
<?php
echo "<h1>PrestaShop Installation Required</h1>";
echo "<p>Database: <?php echo getenv('DB_ENDPOINT'); ?></p>";
echo "<p>Please complete manual installation.</p>";
PHPEOF
}

# Set proper permissions
chown -R nginx:nginx $PRESTASHOP_DIR
find $PRESTASHOP_DIR -type d -exec chmod 775 {} \;
find $PRESTASHOP_DIR -type f -exec chmod 664 {} \;

# Set specific writable directories
chmod -R 775 $PRESTASHOP_DIR/var 2>/dev/null || true
chmod -R 775 $PRESTASHOP_DIR/img 2>/dev/null || true
chmod -R 775 $PRESTASHOP_DIR/upload 2>/dev/null || true
chmod -R 775 $PRESTASHOP_DIR/download 2>/dev/null || true
chmod -R 775 $PRESTASHOP_DIR/app/config 2>/dev/null || true

# ========================================
# 6. CONFIGURE PRESTASHOP
# ========================================
echo "[6/8] Configuring PrestaShop..."

# Only attempt CLI installation if database is accessible
if [ -n "$DB_ENDPOINT" ] && [ -n "$DB_PASSWORD" ]; then
    echo "Attempting PrestaShop CLI installation..."

    # Wait for database to be ready
    for i in {1..30}; do
        if mysql -h "$DB_ENDPOINT" -u "$DB_USERNAME" -p"$DB_PASSWORD" -e "SELECT 1" &>/dev/null; then
            echo "Database is ready"
            break
        fi
        echo "Waiting for database... ($i/30)"
        sleep 10
    done

    # Run PrestaShop installation
    if [ -f "$PRESTASHOP_DIR/install/index_cli.php" ]; then
        cd $PRESTASHOP_DIR
        sudo -u nginx php install/index_cli.php \
            --domain="$DOMAIN" \
            --db_server="$DB_ENDPOINT" \
            --db_name="$DB_NAME" \
            --db_user="$DB_USERNAME" \
            --db_password="$DB_PASSWORD" \
            --email="$ADMIN_EMAIL" \
            --password="$ADMIN_PASSWORD" \
            --firstname="Admin" \
            --lastname="User" \
            --language="en" \
            --country="us" \
            --newsletter=0 \
            --send_email=0 && {
            echo "PrestaShop installed successfully"
            rm -rf $PRESTASHOP_DIR/install
        } || echo "WARNING: PrestaShop CLI installation failed. Manual setup may be required."
    fi
fi

# Create health check file
cat > $PRESTASHOP_DIR/health_check.php <<'EOF'
<?php
http_response_code(200);
echo "OK";
EOF
chown nginx:nginx $PRESTASHOP_DIR/health_check.php

# ========================================
# 7. CONFIGURE CLOUDWATCH AGENT
# ========================================
echo "[7/8] Configuring CloudWatch Agent..."

mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<CWEOF
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/nginx/access.log",
                        "log_group_name": "/aws/ec2/$PROJECT_NAME/$ENVIRONMENT/nginx/access",
                        "log_stream_name": "{instance_id}"
                    },
                    {
                        "file_path": "/var/log/nginx/error.log",
                        "log_group_name": "/aws/ec2/$PROJECT_NAME/$ENVIRONMENT/nginx/error",
                        "log_stream_name": "{instance_id}"
                    },
                    {
                        "file_path": "$PRESTASHOP_DIR/var/logs/*.log",
                        "log_group_name": "/aws/ec2/$PROJECT_NAME/$ENVIRONMENT/prestashop/system",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "$PROJECT_NAME/$ENVIRONMENT",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    {"name": "cpu_usage_idle", "rename": "CPU_USAGE_IDLE", "unit": "Percent"},
                    {"name": "cpu_usage_iowait", "rename": "CPU_USAGE_IOWAIT", "unit": "Percent"},
                    {"name": "cpu_usage_user", "rename": "CPU_USAGE_USER", "unit": "Percent"},
                    {"name": "cpu_usage_system", "rename": "CPU_USAGE_SYSTEM", "unit": "Percent"}
                ],
                "totalcpu": false
            },
            "disk": {
                "measurement": [
                    {"name": "used_percent", "rename": "DISK_USED_PERCENT", "unit": "Percent"}
                ],
                "resources": ["*"]
            },
            "mem": {
                "measurement": [
                    {"name": "mem_used_percent", "rename": "MEM_USED_PERCENT", "unit": "Percent"}
                ]
            }
        }
    }
}
CWEOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# ========================================
# 8. FINAL CHECKS
# ========================================
echo "[8/8] Final verification..."

# Restart services to ensure everything is running
systemctl restart php-fpm
systemctl restart nginx

# Verify services are running
systemctl is-active --quiet nginx && echo "✓ Nginx is running" || echo "✗ Nginx failed"
systemctl is-active --quiet php-fpm && echo "✓ PHP-FPM is running" || echo "✗ PHP-FPM failed"
systemctl is-active --quiet amazon-cloudwatch-agent && echo "✓ CloudWatch Agent is running" || echo "✗ CloudWatch Agent failed"
systemctl is-active --quiet amazon-ssm-agent && echo "✓ SSM Agent is running" || echo "✗ SSM Agent failed"

echo "=========================================="
echo "User-data completed at $(date)"
echo "=========================================="
echo "PrestaShop Directory: $PRESTASHOP_DIR"
echo "Domain: $DOMAIN"
echo "Database: $DB_ENDPOINT"
echo "=========================================="
