#!/bin/bash

set -e

echo "📊 Métriques WAF et CloudFront"
echo "=============================="
echo ""

# Récupérer les IDs
WAF_ACL_ID=$(terraform output -raw waf_web_acl_id 2>/dev/null)
CF_DIST_ID=$(terraform output -json 2>/dev/null | jq -r '.primary_cloudfront_domain.value' | cut -d'.' -f1)

if [ -z "$WAF_ACL_ID" ]; then
  echo "❌ Erreur : WAF ACL ID introuvable"
  exit 1
fi

# Fonction pour récupérer les métriques CloudWatch
get_metric() {
  local namespace=$1
  local metric_name=$2
  local dimensions=$3
  local region=$4
  
  aws cloudwatch get-metric-statistics \
    --region "$region" \
    --namespace "$namespace" \
    --metric-name "$metric_name" \
    --dimensions $dimensions \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 3600 \
    --statistics Sum \
    --query 'Datapoints[0].Sum' \
    --output text 2>/dev/null || echo "0"
}

get_metric_avg() {
  local namespace=$1
  local metric_name=$2
  local dimensions=$3
  local region=$4
  
  aws cloudwatch get-metric-statistics \
    --region "$region" \
    --namespace "$namespace" \
    --metric-name "$metric_name" \
    --dimensions $dimensions \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 3600 \
    --statistics Average \
    --query 'Datapoints[0].Average' \
    --output text 2>/dev/null || echo "0"
}

# Métriques WAF (dernière heure)
echo "🛡️  WAF Metrics (dernière heure):"
echo "--------------------------------"

ALLOWED=$(get_metric "AWS/WAFV2" "AllowedRequests" "Name=WebACL,Value=$WAF_ACL_ID Name=Region,Value=CLOUDFRONT" "us-east-1")
BLOCKED=$(get_metric "AWS/WAFV2" "BlockedRequests" "Name=WebACL,Value=$WAF_ACL_ID Name=Region,Value=CLOUDFRONT" "us-east-1")

echo "  Requêtes autorisées : $ALLOWED"
echo "  Requêtes bloquées   : $BLOCKED"

if [ "$ALLOWED" != "None" ] && [ "$BLOCKED" != "None" ] && [ "$ALLOWED" != "0" ]; then
  TOTAL=$((ALLOWED + BLOCKED))
  BLOCK_RATE=$(awk "BEGIN {printf \"%.2f\", ($BLOCKED / $TOTAL) * 100}")
  echo "  Taux de blocage     : $BLOCK_RATE%"
fi
echo ""

# Métriques CloudFront (dernière heure)
if [ -n "$CF_DIST_ID" ] && [ "$CF_DIST_ID" != "null" ]; then
  echo "📦 CloudFront Metrics (dernière heure):"
  echo "------------------------------------"
  
  REQUESTS=$(get_metric "AWS/CloudFront" "Requests" "Name=DistributionId,Value=$CF_DIST_ID" "us-east-1")
  CACHE_HIT_RATE=$(get_metric_avg "AWS/CloudFront" "CacheHitRate" "Name=DistributionId,Value=$CF_DIST_ID" "us-east-1")
  
  echo "  Total requêtes      : $REQUESTS"
  echo "  Taux de cache hit   : $CACHE_HIT_RATE%"
  
  if [ "$CACHE_HIT_RATE" != "None" ] && [ "$CACHE_HIT_RATE" != "0" ]; then
    if (( $(echo "$CACHE_HIT_RATE > 60" | bc -l) )); then
      echo "  ✅ Excellent taux de cache (>60%)"
    elif (( $(echo "$CACHE_HIT_RATE > 40" | bc -l) )); then
      echo "  ⚠️  Taux de cache moyen (40-60%)"
    else
      echo "  ❌ Taux de cache faible (<40%)"
    fi
  fi
  echo ""
fi

# Détails des règles WAF
echo "📋 Détails des règles WAF:"
echo "-------------------------"

SQL_BLOCKED=$(get_metric "AWS/WAFV2" "BlockedRequests" "Name=WebACL,Value=$WAF_ACL_ID Name=Rule,Value=block-sql-injection Name=Region,Value=CLOUDFRONT" "us-east-1")
XSS_BLOCKED=$(get_metric "AWS/WAFV2" "BlockedRequests" "Name=WebACL,Value=$WAF_ACL_ID Name=Rule,Value=block-xss-bad-inputs Name=Region,Value=CLOUDFRONT" "us-east-1")
RATE_BLOCKED=$(get_metric "AWS/WAFV2" "BlockedRequests" "Name=WebACL,Value=$WAF_ACL_ID Name=Rule,Value=rate-limit-per-ip Name=Region,Value=CLOUDFRONT" "us-east-1")

echo "  SQL Injection bloquées    : $SQL_BLOCKED"
echo "  XSS bloquées              : $XSS_BLOCKED"
echo "  Rate Limit dépassé        : $RATE_BLOCKED"
echo ""

# Dashboard URLs
echo "============================================"
echo "🔗 Liens vers les dashboards AWS:"
echo "============================================"
echo ""
echo "WAF Console:"
echo "https://console.aws.amazon.com/wafv2/homev2/web-acl/$WAF_ACL_ID/overview?region=global"
echo ""
echo "CloudFront Console:"
echo "https://console.aws.amazon.com/cloudfront/v3/home#/distributions/$CF_DIST_ID"
echo ""
echo "CloudWatch Metrics:"
echo "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#metricsV2:graph=~(metrics~(~(~'AWS*2fWAFV2~'AllowedRequests)))"
echo ""