resource "aws_security_group" "this" {
  name_prefix = "${var.identifier}-"
  description = "Allow PostgreSQL access to ${var.identifier}"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = toset(var.allowed_security_group_ids)

    content {
      description     = "PostgreSQL from security group ${ingress.value}"
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  dynamic "ingress" {
    for_each = length(var.allowed_cidr_blocks) > 0 ? [1] : []

    content {
      description = "PostgreSQL from allowed CIDR blocks"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
    }
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name    = "${var.identifier}-sg"
    Service = "rds"
  })
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnets"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name    = "${var.identifier}-subnets"
    Service = "rds"
  })
}

resource "aws_db_instance" "this" {
  identifier = var.identifier

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.allocated_storage * 2
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.database_name
  username = var.master_username

  manage_master_user_password         = true
  iam_database_authentication_enabled = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period = var.backup_retention_period
  copy_tags_to_snapshot   = true
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot

  auto_minor_version_upgrade = true
  apply_immediately          = true

  performance_insights_enabled = false
  enabled_cloudwatch_logs_exports = [
    "postgresql",
    "upgrade"
  ]

  tags = merge(var.tags, {
    Name    = var.identifier
    Service = "rds"
  })
}
