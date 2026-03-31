terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_wafv2_web_acl" "alb" {
  name  = "${var.project_name}-${var.environment}-waf-alb"
  scope = "REGIONAL" # Pour ALB (pas CLOUDFRONT)

  default_action {
    allow {}
  }

  dynamic "rule" {
    for_each = length(var.allowlist_ipv4_cidrs) > 0 ? [1] : []
    content {
      name     = "allowlisted-ips"
      priority = 0

      action {
        allow {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.allowlist[0].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "AllowlistRule-ALB"
        sampled_requests_enabled   = true
      }
    }
  }


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
      metric_name                = "SQLiRule-ALB"
      sampled_requests_enabled   = true
    }
  }

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
      metric_name                = "XSSRule-ALB"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "aws-core-rule-set"
    priority = 3

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CoreRuleSet-ALB"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "rate-limit-per-ip"
    priority = 4

    statement {
      rate_based_statement {
        limit              = 2000 # 2000 req/5min par IP
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
      metric_name                = "RateLimitRule-ALB"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-${var.environment}-WAF-ALB"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-waf-alb"
    Environment = var.environment
  }
}

resource "aws_wafv2_ip_set" "allowlist" {
  count = length(var.allowlist_ipv4_cidrs) > 0 ? 1 : 0

  name               = "${var.project_name}-${var.environment}-waf-alb-allowlist"
  description        = "Allowlisted IPv4 addresses for load tests and ops access"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = var.allowlist_ipv4_cidrs

  tags = {
    Name        = "${var.project_name}-${var.environment}-waf-alb-allowlist"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "aws-waf-logs-${var.project_name}-${var.environment}-alb"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-${var.environment}-waf-alb-logs"
    Environment = var.environment
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "main" {
  resource_arn            = aws_wafv2_web_acl.alb.arn
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

resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.alb.arn
}
