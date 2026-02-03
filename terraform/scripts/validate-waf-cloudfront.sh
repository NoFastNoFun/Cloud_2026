#!/bin/bash

set -e

echo "🔍 Validation WAF + CloudFront"
echo "=============================="
echo ""

# Récupérer l'URL CloudFront
CLOUDFRONT_URL=$(terraform output -raw primary_cloudfront_url 2>/dev/null)

if [ -z "$CLOUDFRONT_URL" ]; then
  echo "❌ Erreur : CloudFront URL introuvable"
  echo "Assurez-vous d'être dans le bon répertoire terraform et d'avoir déployé l'infrastructure"
  exit 1
fi

echo "URL testée : $CLOUDFRONT_URL"
echo ""

# Test 1 : Requête normale
echo "✅ Test 1 : Requête normale"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$CLOUDFRONT_URL")
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
  echo "   ✓ Succès (HTTP $HTTP_CODE)"
else
  echo "   ✗ Échec (HTTP $HTTP_CODE)"
fi
echo ""

# Test 2 : SQL Injection (doit être bloqué)
echo "🛡️  Test 2 : SQL Injection (doit être bloqué)"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$CLOUDFRONT_URL/app/login" \
  -d "username=admin' OR '1'='1")
if [ "$HTTP_CODE" = "403" ]; then
  echo "   ✓ Bloqué avec succès (HTTP 403)"
else
  echo "   ⚠️  Attention : pas bloqué (HTTP $HTTP_CODE)"
  echo "   Note : Le WAF peut prendre quelques minutes pour être actif"
fi
echo ""

# Test 3 : XSS (doit être bloqué)
echo "🛡️  Test 3 : XSS (doit être bloqué)"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$CLOUDFRONT_URL/app/search" \
  -d "query=<script>alert('xss')</script>")
if [ "$HTTP_CODE" = "403" ]; then
  echo "   ✓ Bloqué avec succès (HTTP 403)"
else
  echo "   ⚠️  Attention : pas bloqué (HTTP $HTTP_CODE)"
  echo "   Note : Le WAF peut prendre quelques minutes pour être actif"
fi
echo ""

# Test 4 : Path Traversal (doit être bloqué)
echo "🛡️  Test 4 : Path Traversal (doit être bloqué)"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$CLOUDFRONT_URL/../../etc/passwd")
if [ "$HTTP_CODE" = "403" ]; then
  echo "   ✓ Bloqué avec succès (HTTP 403)"
else
  echo "   ⚠️  Attention : pas bloqué (HTTP $HTTP_CODE)"
fi
echo ""

# Test 5 : Vérification du cache CloudFront
echo "📦 Test 5 : Cache CloudFront (images)"
echo "   Première requête (cache miss)..."
RESPONSE1=$(curl -s -I "$CLOUDFRONT_URL/logo.png" 2>&1)
CACHE_STATUS1=$(echo "$RESPONSE1" | grep -i "x-cache" || echo "   x-cache header non trouvé")
echo "   $CACHE_STATUS1"

echo "   Deuxième requête (doit venir du cache)..."
sleep 2
RESPONSE2=$(curl -s -I "$CLOUDFRONT_URL/logo.png" 2>&1)
CACHE_STATUS2=$(echo "$RESPONSE2" | grep -i "x-cache" || echo "   x-cache header non trouvé")
echo "   $CACHE_STATUS2"
echo ""

# Test 6 : Compression
echo "📊 Test 6 : Vérification de la compression"
ENCODING=$(curl -s -I -H "Accept-Encoding: gzip" "$CLOUDFRONT_URL" | grep -i "content-encoding" || echo "   Pas de compression détectée")
echo "   $ENCODING"
echo ""

# Test 7 : Rate Limiting (léger)
echo "⚡ Test 7 : Rate Limiting (10 requêtes rapides)"
echo "   Envoi de 10 requêtes..."
for i in {1..10}; do
  curl -s -o /dev/null -w "." "$CLOUDFRONT_URL"
done
echo ""
echo "   ✓ Terminé (surveillez les métriques WAF pour le rate limiting)"
echo ""

# Résumé
echo "============================================"
echo "📊 RÉSUMÉ"
echo "============================================"
WAF_ID=$(terraform output -raw waf_web_acl_id 2>/dev/null)
CF_ID=$(terraform output -raw primary_cloudfront_domain 2>/dev/null | cut -d'.' -f1)

echo ""
echo "📌 Liens utiles:"
echo ""
echo "WAF Dashboard:"
echo "https://console.aws.amazon.com/wafv2/homev2/web-acl/$WAF_ID/overview?region=global"
echo ""
echo "CloudFront Monitoring:"
echo "https://console.aws.amazon.com/cloudfront/v3/home#/distributions/$CF_ID"
echo ""
echo "============================================"
echo ""
echo "✅ Validation terminée!"
echo ""
echo "Note : Si certains tests échouent, attendez 5-10 minutes"
echo "que CloudFront et WAF se synchronisent complètement."