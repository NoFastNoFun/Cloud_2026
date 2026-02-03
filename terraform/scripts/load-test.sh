#!/bin/bash

# Script de test de charge simple
# Pour un test plus complet, utilisez JMeter ou Locust

CLOUDFRONT_URL=$(terraform output -raw primary_cloudfront_url 2>/dev/null)
CONCURRENT_USERS=${1:-100}
REQUESTS_PER_USER=${2:-10}

echo "🚀 Test de charge"
echo "================="
echo "URL: $CLOUDFRONT_URL"
echo "Utilisateurs concurrents: $CONCURRENT_USERS"
echo "Requêtes par utilisateur: $REQUESTS_PER_USER"
echo ""

# Utiliser Apache Bench si disponible
if command -v ab &> /dev/null; then
  echo "Utilisation d'Apache Bench..."
  TOTAL_REQUESTS=$((CONCURRENT_USERS * REQUESTS_PER_USER))
  ab -n $TOTAL_REQUESTS -c $CONCURRENT_USERS "$CLOUDFRONT_URL/"
else
  echo "⚠️  Apache Bench (ab) non installé"
  echo "Installation : sudo apt-get install apache2-utils  (Ubuntu/Debian)"
  echo "              sudo yum install httpd-tools         (CentOS/RHEL)"
  exit 1
fi