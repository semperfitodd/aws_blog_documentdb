resource "aws_docdb_cluster" "documentdb" {
  apply_immediately               = true
  backup_retention_period         = 1
  cluster_identifier              = "${local.environment}-cluster"
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.documentdb.name
  db_subnet_group_name            = aws_docdb_subnet_group.documentdb.name
  deletion_protection             = true
  enabled_cloudwatch_logs_exports = ["profiler"]
  master_password                 = random_string.password.result
  master_username                 = "administrator"
  preferred_backup_window         = "07:00-09:00"
  preferred_maintenance_window    = "Mon:22:00-Mon:23:00"
  skip_final_snapshot             = true
  storage_encrypted               = true
  tags                            = var.tags
  vpc_security_group_ids          = [aws_security_group.documentdb.id]
}

resource "aws_docdb_cluster_instance" "documentdb" {
  apply_immediately          = true
  auto_minor_version_upgrade = true
  cluster_identifier         = aws_docdb_cluster.documentdb.id
  identifier                 = aws_docdb_cluster.documentdb.cluster_identifier
  instance_class             = "db.t4g.medium"
  tags                       = var.tags

  depends_on = [aws_docdb_cluster.documentdb]
}

resource "aws_docdb_cluster_parameter_group" "documentdb" {
  name        = local.environment
  description = "${local.environment} DocumentDB cluster parameter group"
  family      = "docdb5.0"

  tags = var.tags
}

resource "aws_docdb_subnet_group" "documentdb" {
  name        = "documentdb_${local.environment}"
  description = "Allowed subnets for DocumentDB cluster instances"
  subnet_ids  = module.vpc.database_subnets
  tags        = var.tags
}

resource "aws_secretsmanager_secret" "documentdb" {
  name                    = "${local.environment}-credentials"
  description             = "${local.environment} DocumentDB credentials"
  recovery_window_in_days = "7"
  tags                    = var.tags

  depends_on = [aws_docdb_cluster.documentdb]
}

resource "aws_secretsmanager_secret_version" "password" {
  secret_id = aws_secretsmanager_secret.documentdb.id
  secret_string = jsonencode(
    {
      username = aws_docdb_cluster.documentdb.master_username
      password = aws_docdb_cluster.documentdb.master_password
    }
  )

  lifecycle {
    ignore_changes = [secret_string]
  }

  depends_on = [aws_secretsmanager_secret.documentdb]
}

resource "aws_security_group" "documentdb" {
  name        = "${local.environment}_docdb"
  description = "Security Group for DocumentDB cluster"
  vpc_id      = module.vpc.vpc_id
  tags        = var.tags
}

resource "aws_security_group_rule" "documentdb_egress" {
  type              = "egress"
  description       = "Allow all egress traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.documentdb.id
}

resource "aws_security_group_rule" "documentdb_app_ingress" {
  type              = "ingress"
  description       = "Allow inbound traffic from VPC CIDR"
  from_port         = aws_docdb_cluster.documentdb.port
  to_port           = aws_docdb_cluster.documentdb.port
  protocol          = "tcp"
  security_group_id = aws_security_group.documentdb.id

  cidr_blocks = [module.vpc.vpc_cidr_block]
}

resource "random_string" "password" {
  length  = 16
  special = false
}