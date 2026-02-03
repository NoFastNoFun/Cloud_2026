# Origin Access Control for S3 (gardez tel quel)
resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "${var.project_name}-${var.environment}-oac"
  description                       = "OAC for S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true  # ✅ CHANGEMENT : Activez IPv6 pour plus de capacité
  comment             = "CloudFront distribution for ${var.project_name}"
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  
  # ✅ NOUVEAU : WAF Association
  web_acl_id = var.waf_acl_id

  # --- Origin 1 : S3 (assets)
  origin {
    domain_name              = var.s3_bucket_domain
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
    origin_id                = "S3-${var.project_name}-${var.environment}"
  }

  # --- Origin 2 : ALB (dynamic)
  origin {
    domain_name = var.alb_domain_name
    origin_id   = "ALB-${var.project_name}-${var.environment}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
      
      # ✅ NOUVEAU : Timeouts optimisés pour haute charge
      origin_keepalive_timeout = 60
      origin_read_timeout      = 60
    }
    
    # ✅ NOUVEAU : Custom headers pour identifier les requêtes CloudFront
    custom_header {
      name  = "X-Custom-Origin-Header"
      value = "${var.project_name}-cloudfront"
    }
  }

  # --- Default behavior : S3 (assets statiques)
  default_cache_behavior {
    target_origin_id = "S3-${var.project_name}-${var.environment}"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]

    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    
    # ✅ NOUVEAU : Cache optimisé pour les assets
    min_ttl     = 0
    default_ttl = 86400      # 1 jour
    max_ttl     = 31536000   # 1 an
  }

  # --- Cache behavior : dynamic requests (/app/*)
  ordered_cache_behavior {
    path_pattern     = "/app/*"
    target_origin_id = "ALB-${var.project_name}-${var.environment}"
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "POST", "PUT", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true  # ✅ AJOUTÉ : Compression

    forwarded_values {
      query_string = true
      headers      = ["Host", "CloudFront-Forwarded-Proto", "User-Agent"]  # ✅ OPTIMISÉ : Uniquement headers nécessaires
      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }
  
  # ✅ NOUVEAU : Comportement pour images (cache maximal)
  ordered_cache_behavior {
    path_pattern           = "*.jpg"
    target_origin_id       = "S3-${var.project_name}-${var.environment}"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    min_ttl     = 86400
    default_ttl = 604800
    max_ttl     = 31536000
  }

  ordered_cache_behavior {
    path_pattern           = "*.png"
    target_origin_id       = "S3-${var.project_name}-${var.environment}"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    min_ttl     = 86400
    default_ttl = 604800
    max_ttl     = 31536000
  }

  ordered_cache_behavior {
    path_pattern           = "*.gif"
    target_origin_id       = "S3-${var.project_name}-${var.environment}"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    min_ttl     = 86400
    default_ttl = 604800
    max_ttl     = 31536000
  }
  
  # ✅ NOUVEAU : CSS
  ordered_cache_behavior {
    path_pattern           = "*.css"
    target_origin_id       = "S3-${var.project_name}-${var.environment}"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    min_ttl     = 86400
    default_ttl = 604800
    max_ttl     = 31536000
  }
  
  # ✅ NOUVEAU : JavaScript
  ordered_cache_behavior {
    path_pattern           = "*.js"
    target_origin_id       = "S3-${var.project_name}-${var.environment}"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    min_ttl     = 86400
    default_ttl = 604800
    max_ttl     = 31536000
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cloudfront"
  }
}