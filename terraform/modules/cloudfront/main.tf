resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "${var.project_name}-${var.environment}-${substr(md5(var.s3_bucket_domain), 0, 8)}-oac"
  description                       = "OAC for S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = false
  comment             = "CloudFront distribution for ${var.project_name}"
  default_root_object = "" # PrestaShop gère ses propres routes
  price_class         = "PriceClass_100"

  web_acl_id = var.web_acl_id

  origin {
    domain_name              = var.s3_bucket_domain
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
    origin_id                = "S3-Assets"
  }

  origin {
    domain_name = var.alb_dns_name
    origin_id   = "ALB-Prestashop"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" # L'ALB reçoit en HTTP depuis CloudFront
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ALB-Prestashop"

    forwarded_values {
      query_string = true # Important pour les recherches et filtres PrestaShop
      cookies {
        forward = "all" # Important pour le panier et les sessions clients
      }
      headers = ["Host", "Origin", "Authorization"] # Transmet les headers vitaux
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0 # On ne cache pas le contenu dynamique par défaut
    max_ttl                = 0
  }

  ordered_cache_behavior {
    path_pattern     = "/img/*" # Dossier standard des images PrestaShop
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Assets"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
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
    Name        = "${var.project_name}-${var.environment}-cloudfront"
    Environment = var.environment
  }
}
