#!/bin/bash
set -e

# Update system
yum update -y

# Install required packages
yum install -y \
    git \
    wget \
    unzip \
    amazon-cloudwatch-agent \
    amazon-ssm-agent

# Start SSM agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Install Ansible
yum install -y python3 python3-pip
pip3 install ansible boto3

# Create directory for Ansible
mkdir -p /opt/ansible
cd /opt/ansible

# Download Ansible playbook from S3 or use inline
# For now, we'll install PrestaShop directly in user-data
# In production, you would pull the playbook from S3 or Git

# Install Nginx
yum install -y nginx
systemctl enable nginx

# Install PHP ${php_version} and extensions
amazon-linux-extras enable php${php_version}
yum install -y \
    php \
    php-fpm \
    php-cli \
    php-common \
    php-gd \
    php-intl \
    php-mbstring \
    php-mysqlnd \
    php-opcache \
    php-xml \
    php-zip \
    php-json \
    php-curl \
    php-bcmath \
    php-soap

# Install MySQL client
yum install -y mysql

# Install Composer
cd /tmp
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer

# Configure PHP-FPM
sed -i 's/user = apache/user = nginx/' /etc/php-fpm.d/www.conf
sed -i 's/group = apache/group = nginx/' /etc/php-fpm.d/www.conf
systemctl enable php-fpm
systemctl start php-fpm

# Create PrestaShop directory
mkdir -p /var/www/prestashop
chown -R nginx:nginx /var/www/prestashop

# Install PrestaShop via Composer
cd /var/www/prestashop
sudo -u nginx /usr/local/bin/composer create-project prestashop/prestashop . "${prestashop_version}" --no-dev --prefer-dist --no-interaction

# Set permissions
chown -R nginx:nginx /var/www/prestashop
find /var/www/prestashop/var -type d -exec chmod 775 {} \;
find /var/www/prestashop/var -type f -exec chmod 664 {} \;
find /var/www/prestashop/img -type d -exec chmod 775 {} \;
find /var/www/prestashop/img -type f -exec chmod 664 {} \;
find /var/www/prestashop/upload -type d -exec chmod 775 {} \;
find /var/www/prestashop/upload -type f -exec chmod 664 {} \;
find /var/www/prestashop/download -type d -exec chmod 775 {} \;
find /var/www/prestashop/download -type f -exec chmod 664 {} \;

# Configure Nginx for PrestaShop
cat > /etc/nginx/conf.d/prestashop.conf <<EOF
upstream fastcgi_backend {
    server 127.0.0.1:9000;
}

server {
    listen 80;
    server_name _;
    root /var/www/prestashop;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_pass fastcgi_backend;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_read_timeout 300;
    }

    location ~ ^/(app|bin|cache|classes|config|controllers|docs|localization|override|src|tests|tools|translations|upload|var|vendor)/ {
        deny all;
    }

    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF

# Start Nginx
systemctl start nginx

# Install PrestaShop via CLI (non-interactive)
PRESTASHOP_DOMAIN="${prestashop_domain}"
if [ -z "$PRESTASHOP_DOMAIN" ]; then
    PRESTASHOP_DOMAIN="localhost"
fi

cd /var/www/prestashop
sudo -u nginx php install/index_cli.php \
    --domain=${PRESTASHOP_DOMAIN} \
    --db_server="${db_endpoint}" \
    --db_name="${db_name}" \
    --db_user="${db_username}" \
    --db_password="${db_password}" \
    --email="${prestashop_admin_email}" \
    --password="${prestashop_admin_password}" \
    --firstname=Admin \
    --lastname=User \
    --language=en \
    --country=us \
    --newsletter=0 \
    --send_email=0 || true

# Remove install directory after installation (if successful)
if [ -f /var/www/prestashop/app/config/parameters.php ]; then
    rm -rf /var/www/prestashop/install
fi

# Configure CloudWatch Agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/nginx/access.log",
                        "log_group_name": "/aws/ec2/${project_name}/${environment}/nginx/access",
                        "log_stream_name": "{instance_id}"
                    },
                    {
                        "file_path": "/var/log/nginx/error.log",
                        "log_group_name": "/aws/ec2/${project_name}/${environment}/nginx/error",
                        "log_stream_name": "{instance_id}"
                    },
                    {
                        "file_path": "/var/www/prestashop/var/logs/system.log",
                        "log_group_name": "/aws/ec2/${project_name}/${environment}/prestashop/system",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "${project_name}/${environment}",
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
EOF

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

# Create health check file
echo "OK" > /var/www/prestashop/health_check.php
chown nginx:nginx /var/www/prestashop/health_check.php

# Signal completion
echo "PrestaShop installation completed at $(date)" >> /var/log/prestashop-install.log
