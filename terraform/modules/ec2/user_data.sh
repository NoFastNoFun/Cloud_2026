#!/bin/bash
set -euo pipefail

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting user-data script at $(date)"

yum install -y git wget unzip nginx php php-fpm php-cli php-common php-gd php-intl php-mbstring php-mysqlnd php-opcache php-xml php-zip php-curl amazon-cloudwatch-agent amazon-ssm-agent mariadb105

systemctl enable --now amazon-ssm-agent
systemctl enable nginx

# PHP-FPM baseline
sed -i 's/user = apache/user = nginx/' /etc/php-fpm.d/www.conf || true
sed -i 's/group = apache/group = nginx/' /etc/php-fpm.d/www.conf || true
systemctl enable --now php-fpm

mkdir -p /var/www/html
chown -R nginx:nginx /var/www/html

# Nginx: healthz stable + simple page
cat > /etc/nginx/conf.d/app.conf <<'EOF'
server {
  listen 80 default_server;
  server_name _;

  location = /healthz {
    access_log off;
    return 200 "ok";
    add_header Content-Type text/plain;
  }

  root /var/www/html;
  index index.html;

  location / {
    try_files $uri $uri/ =404;
  }
}
EOF

rm -f /etc/nginx/conf.d/default.conf || true
nginx -t
systemctl restart nginx

cat > /var/www/html/index.html <<'EOF'
<!DOCTYPE html>
<html><head><title>Ready</title></head>
<body><h1>Instance ready</h1><p>Waiting for Ansible/Deploy.</p></body></html>
EOF
chown nginx:nginx /var/www/html/index.html

echo "User-data completed at $(date)"
