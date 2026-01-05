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
# For now, we'll install Magento directly in user-data
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

# Configure PHP-FPM
sed -i 's/user = apache/user = nginx/' /etc/php-fpm.d/www.conf
sed -i 's/group = apache/group = nginx/' /etc/php-fpm.d/www.conf
systemctl enable php-fpm
systemctl start php-fpm

# Create Magento directory
mkdir -p /var/www/magento
chown -R nginx:nginx /var/www/magento

# Download and install Magento
cd /tmp
MAGENTO_VERSION="${magento_version}"
wget https://github.com/magento/magento2/archive/${MAGENTO_VERSION}.zip
unzip ${MAGENTO_VERSION}.zip
mv magento2-${MAGENTO_VERSION}/* /var/www/magento/
mv magento2-${MAGENTO_VERSION}/.htaccess /var/www/magento/ 2>/dev/null || true
rm -rf magento2-${MAGENTO_VERSION} ${MAGENTO_VERSION}.zip

# Set permissions
chown -R nginx:nginx /var/www/magento
find /var/www/magento -type d -exec chmod 770 {} \;
find /var/www/magento -type f -exec chmod 660 {} \;
chmod +x /var/www/magento/bin/magento

# Configure Nginx for Magento
cat > /etc/nginx/conf.d/magento.conf <<EOF
upstream fastcgi_backend {
    server 127.0.0.1:9000;
}

server {
    listen 80;
    server_name _;
    set \$MAGE_ROOT /var/www/magento;
    include /var/www/magento/nginx.conf.sample;
}
EOF

# Start Nginx
systemctl start nginx

# Install Magento via CLI (non-interactive)
cd /var/www/magento
sudo -u nginx php bin/magento setup:install \
    --base-url="${magento_base_url}/" \
    --db-host="${db_endpoint}" \
    --db-name="${db_name}" \
    --db-user="${db_username}" \
    --db-password="${db_password}" \
    --admin-firstname=Admin \
    --admin-lastname=User \
    --admin-email="${magento_admin_email}" \
    --admin-user="${magento_admin_username}" \
    --admin-password="${magento_admin_password}" \
    --language=en_US \
    --currency=USD \
    --timezone=America/New_York \
    --use-rewrites=1 \
    --use-secure=0 \
    --use-secure-admin=0 \
    --backend-frontname=admin \
    --search-engine=elasticsearch7 \
    --elasticsearch-host=localhost \
    --elasticsearch-port=9200 \
    --elasticsearch-index-prefix=magento2 \
    --elasticsearch-timeout=15

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
                        "file_path": "/var/www/magento/var/log/system.log",
                        "log_group_name": "/aws/ec2/${project_name}/${environment}/magento/system",
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
echo "OK" > /var/www/magento/health_check.php
chown nginx:nginx /var/www/magento/health_check.php

# Signal completion
echo "Magento installation completed at $(date)" >> /var/log/magento-install.log

