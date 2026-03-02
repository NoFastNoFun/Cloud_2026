#!/bin/bash
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
echo "user-data started at $(date)"
set -o pipefail

cat > /etc/sysctl.d/99-high-concurrency.conf <<'SYSCTL'
fs.file-max = 100000
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_max_tw_buckets = 1440000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 5
vm.swappiness = 10
SYSCTL

sysctl --system

cat > /etc/security/limits.d/99-high-concurrency.conf <<'LIMITS'
* soft nofile 100000
* hard nofile 100000
nginx soft nofile 100000
nginx hard nofile 100000
LIMITS

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

{
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
  ulimit -n
} >> /var/log/kernel-tuning-verification.log 2>&1

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

echo "[1/8] System setup..."
yum update -y || true
yum install -y \
    git wget unzip vim htop \
    nginx \
    php php-fpm php-cli php-common php-gd php-intl php-mbstring \
    php-mysqlnd php-opcache php-xml php-curl \
    php-bcmath php-soap \
    amazon-cloudwatch-agent \
    amazon-ssm-agent || yum install -y nginx php php-fpm php-cli php-mysqlnd amazon-cloudwatch-agent amazon-ssm-agent

yum install -y mariadb105 || yum install -y mariadb || true
yum install -y php-zip || true

# Set timezone
timedatectl set-timezone UTC || true

# Enable SSM agent
systemctl enable --now amazon-ssm-agent || true

echo "[2/8] PHP config..."

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

systemctl enable php-fpm || true
systemctl start php-fpm || true

echo "[3/8] Nginx config..."
rm -f /etc/nginx/conf.d/default.conf
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

    location = /healthz {
        access_log off;
        return 200 "ok";
        add_header Content-Type text/plain;
    }

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

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ ^/(app|bin|cache|classes|config|controllers|docs|localization|override|src|tests|tools|translations|upload|var|vendor)/ {
        deny all;
    }

    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

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

nginx -t || echo "WARNING: nginx -t a echoue, verification de la config..."
systemctl enable nginx || true
systemctl start nginx || true

echo "[4/8] Composer..."
set +o pipefail
curl -sS https://getcomposer.org/installer | php
set -o pipefail
mv composer.phar /usr/local/bin/composer || true
chmod +x /usr/local/bin/composer || true

echo "[5/8] PrestaShop..."
mkdir -p $PRESTASHOP_DIR
chown -R nginx:nginx $PRESTASHOP_DIR

cd /tmp
sudo -u nginx COMPOSER_HOME=/tmp/composer /usr/local/bin/composer create-project \
    prestashop/prestashop $PRESTASHOP_DIR "$PRESTASHOP_VERSION" \
    --no-dev --prefer-dist --no-interaction || {
    mkdir -p $PRESTASHOP_DIR
    cat > $PRESTASHOP_DIR/index.php <<'PHPEOF'
<?php
echo "<h1>PrestaShop Installation Required</h1>";
echo "<p>Database: <?php echo getenv('DB_ENDPOINT'); ?></p>";
echo "<p>Please complete manual installation.</p>";
PHPEOF
}

chown -R nginx:nginx $PRESTASHOP_DIR
find $PRESTASHOP_DIR -type d -exec chmod 775 {} \;
find $PRESTASHOP_DIR -type f -exec chmod 664 {} \;

chmod -R 775 $PRESTASHOP_DIR/var 2>/dev/null || true
chmod -R 775 $PRESTASHOP_DIR/img 2>/dev/null || true
chmod -R 775 $PRESTASHOP_DIR/upload 2>/dev/null || true
chmod -R 775 $PRESTASHOP_DIR/download 2>/dev/null || true
chmod -R 775 $PRESTASHOP_DIR/app/config 2>/dev/null || true

echo "[6/8] PrestaShop config..."
if [ -n "$DB_ENDPOINT" ] && [ -n "$DB_PASSWORD" ]; then
    for i in {1..30}; do
        if mysql -h "$DB_ENDPOINT" -u "$DB_USERNAME" -p"$DB_PASSWORD" -e "SELECT 1" &>/dev/null; then
            break
        fi
        sleep 10
    done

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
            --send_email=0 && rm -rf $PRESTASHOP_DIR/install || true
    fi
fi

cat > $PRESTASHOP_DIR/health_check.php <<'EOF'
<?php
http_response_code(200);
echo "OK";
EOF
chown nginx:nginx $PRESTASHOP_DIR/health_check.php

echo "[7/8] CloudWatch Agent..."

mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWEOF'
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/nginx/access.log",
                        "log_group_name": "/aws/ec2/PROJECT_NAME_PLACEHOLDER/ENVIRONMENT_PLACEHOLDER/nginx/access",
                        "log_stream_name": "{instance_id}"
                    },
                    {
                        "file_path": "/var/log/nginx/error.log",
                        "log_group_name": "/aws/ec2/PROJECT_NAME_PLACEHOLDER/ENVIRONMENT_PLACEHOLDER/nginx/error",
                        "log_stream_name": "{instance_id}"
                    },
                    {
                        "file_path": "/var/www/prestashop/var/logs/*.log",
                        "log_group_name": "/aws/ec2/PROJECT_NAME_PLACEHOLDER/ENVIRONMENT_PLACEHOLDER/prestashop/system",
                        "log_stream_name": "{instance_id}"
                    },
                    {
                        "file_path": "/var/log/user-data.log",
                        "log_group_name": "/aws/ec2/PROJECT_NAME_PLACEHOLDER/ENVIRONMENT_PLACEHOLDER/user-data",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "PROJECT_NAME_PLACEHOLDER/ENVIRONMENT_PLACEHOLDER",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    {"name": "cpu_usage_idle", "unit": "Percent"},
                    {"name": "cpu_usage_iowait", "unit": "Percent"},
                    {"name": "cpu_usage_user", "unit": "Percent"},
                    {"name": "cpu_usage_system", "unit": "Percent"}
                ],
                "totalcpu": false
            },
            "disk": {
                "measurement": [
                    {"name": "used_percent", "unit": "Percent"}
                ],
                "resources": ["*"]
            },
            "mem": {
                "measurement": [
                    {"name": "mem_used_percent", "unit": "Percent"}
                ]
            }
        }
    }
}
CWEOF

# Replace placeholders with actual values
sed -i "s/PROJECT_NAME_PLACEHOLDER/$PROJECT_NAME/g" /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
sed -i "s/ENVIRONMENT_PLACEHOLDER/$ENVIRONMENT/g" /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Verify config file was created
if [ ! -f /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json ]; then
    echo "ERROR: CloudWatch Agent config file not created!"
    exit 1
fi

echo "CloudWatch Agent config created successfully"
cat /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

echo "[8/8] Final checks..."
systemctl restart php-fpm
systemctl restart nginx

systemctl is-active --quiet nginx && echo "OK nginx" || echo "FAIL nginx"
systemctl is-active --quiet php-fpm && echo "OK php-fpm" || echo "FAIL php-fpm"
systemctl is-active --quiet amazon-cloudwatch-agent && echo "OK cwagent" || echo "FAIL cwagent"
systemctl is-active --quiet amazon-ssm-agent && echo "OK ssm" || echo "FAIL ssm"

echo "Done at $(date) | PS=$PRESTASHOP_DIR | DB=$DB_ENDPOINT"
