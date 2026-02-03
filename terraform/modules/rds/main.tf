# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  }
}

# DB Parameter Group
resource "aws_db_parameter_group" "main" {
  name   = "${var.project_name}-${var.environment}-mysql-${replace(var.db_engine_version, ".", "")}"
  family = "mysql${var.db_engine_version}"

  # Optimize for PrestaShop
  parameter {
    name  = "max_connections"
    value = "500"
  }

  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-db-parameter-group"
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${var.environment}-db"

  engine         = "mysql"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_allocated_storage * 1.5
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  parameter_group_name   = aws_db_parameter_group.main.name
  vpc_security_group_ids = [var.security_group_id]

  # Single-AZ for cost optimization (can be changed to true for high availability)
  multi_az = false

  # Backup configuration
  backup_retention_period = 3
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  # Enable automated backups
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-${var.environment}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  deletion_protection       = false

  # Performance Insights (disabled for cost optimization)
  performance_insights_enabled = false

  # Monitoring
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  tags = {
    Name = "${var.project_name}-${var.environment}-db"
  }
}

resource "aws_db_proxy" "main" {
  name                   = "${var.project_name}-${var.environment}-proxy"
  role_arn               = aws_iam_role.rds_proxy_role.arn
  vpc_security_group_ids = [var.security_group_id]
  vpc_subnet_ids         = var.private_subnet_ids

  auth {
    auth_scheme = "SECRETS"
    description = "Authentication for RDS Proxy"
    secret_arn  = aws_secretsmanager_secret.rds_proxy_secret.arn
  }

  require_tls = true

  idle_client_timeout = 1800
  debug_logging       = false

  tags = {
    Name        = "${var.project_name}-${var.environment}-proxy"
    Environment = var.environment
  }
}
