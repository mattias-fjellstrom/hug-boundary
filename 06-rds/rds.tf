data "aws_rds_engine_version" "postgresql" {
  engine  = "aurora-postgresql"
  version = "16.1"
}

resource "aws_rds_cluster_parameter_group" "postgres" {
  name   = "aurora-postgres-boundary"
  family = data.aws_rds_engine_version.postgresql.parameter_group_family

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "rds.force_ssl"
    value = "0"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_rds_cluster" "this" {
  availability_zones = [
    data.aws_availability_zones.available.names[0],
    data.aws_availability_zones.available.names[1],
    data.aws_availability_zones.available.names[2],
  ]

  cluster_identifier              = "aurora-${var.aws_region}"
  database_name                   = var.database_name
  db_subnet_group_name            = aws_db_subnet_group.this.name
  engine                          = data.aws_rds_engine_version.postgresql.engine
  engine_mode                     = "provisioned"
  engine_version                  = data.aws_rds_engine_version.postgresql.version
  master_username                 = var.database_master_username
  master_password                 = data.tfe_outputs.platform.values.boundary_cluster.password
  storage_encrypted               = true
  skip_final_snapshot             = true
  vpc_security_group_ids          = [aws_security_group.db.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.postgres.name

  serverlessv2_scaling_configuration {
    max_capacity = 1.0
    min_capacity = 0.5
  }
}

resource "aws_rds_cluster_instance" "this" {
  cluster_identifier  = aws_rds_cluster.this.id
  instance_class      = "db.serverless"
  engine              = aws_rds_cluster.this.engine
  engine_version      = aws_rds_cluster.this.engine_version
  publicly_accessible = false
}
