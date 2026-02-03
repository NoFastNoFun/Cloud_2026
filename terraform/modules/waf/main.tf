terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

# Web ACL avec règles de protection
resource "aws_wafv2_web_acl" "cloudfront" {
  provider = aws.us_east_1  
  
  name  = "${var.project_name}-${var.environment}-waf-cloudfront"
  scope = "CLOUDFRONT"  

  default_action {
    allow {}
  }

  # Règle 1 : Protection SQL Injection
  rule {
    name     = "block-sql-injection"
    priority = 1

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesSQLiRuleSet"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SQLiRule"
      sampled_requests_enabled   = true
    }
  }

  # Règle 2 : Protection XSS et inputs malveillants
  rule {
    name     = "block-xss-bad-inputs"
    priority = 2

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "XSSRule"
      sampled_requests_enabled   = true
    }
  }

  # Règle 3 : Core Rule Set (OWASP Top 10)
  rule {
    name     = "aws-core-rule-set"
    priority = 3

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
        
        # Exclure certaines règles trop strictes si nécessaire
        # rule_action_override {
        #   name = "SizeRestrictions_BODY"
        #   action_to_use {
        #     count {}
        #   }
        # }
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CoreRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Règle 4 : Rate Limiting (protection DDoS applicative)
  rule {
    name     = "rate-limit-per-ip"
    priority = 4

    statement {
      rate_based_statement {
        limit              = 2000  # 2000 requêtes par IP toutes les 5 minutes
        aggregate_key_type = "IP"
      }
    }

    action {
      block {
        custom_response {
          response_code = 429
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  # Règle 5 : Protection contre les bots (optionnel mais recommandé)
  rule {
    name     = "block-bad-bots"
    priority = 5

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesBotControlRuleSet"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BotControlRule"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-${var.environment}-WAF"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-waf-cloudfront"
    Environment = var.environment
  }
}

# CloudWatch Log Group pour les logs WAF
resource "aws_cloudwatch_log_group" "waf_logs" {
  provider = aws.us_east_1
  
  name              = "/aws/wafv2/${var.project_name}-${var.environment}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-${var.environment}-waf-logs"
    Environment = var.environment
  }
}

# Configuration du logging WAF
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  provider = aws.us_east_1
  
  resource_arn            = aws_wafv2_web_acl.cloudfront.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf_logs.arn]

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  redacted_fields {
    single_header {
      name = "cookie"
    }
  }
}