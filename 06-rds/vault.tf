resource "vault_database_secrets_mount" "postgres" {
  path = "database"

  postgresql {
    name                 = "postgres"
    username             = var.database_master_username
    password             = data.tfe_outputs.platform.values.boundary_cluster.password
    connection_url       = "postgresql://{{username}}:{{password}}@${aws_rds_cluster.this.endpoint}:5432/postgres?sslmode=disable"
    verify_connection    = false
    max_open_connections = 5

    allowed_roles = [
      "readwrite",
      "read",
    ]
  }

  depends_on = [
    aws_rds_cluster.this,
    aws_rds_cluster_instance.this,
  ]
}

resource "vault_database_secret_backend_role" "readwrite" {
  name    = "readwrite"
  backend = vault_database_secrets_mount.postgres.path
  db_name = vault_database_secrets_mount.postgres.postgresql[0].name

  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}' INHERIT;",
    "GRANT CONNECT ON DATABASE postgres TO \"{{name}}\";",
    "REVOKE ALL ON SCHEMA public FROM \"{{name}}\";",
    "GRANT CREATE ON SCHEMA public TO \"{{name}}\";",
    "GRANT ALL ON ALL TABLES IN SCHEMA public TO \"{{name}}\";",
    "GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO \"{{name}}\";",
    "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO \"{{name}}\";",
    "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO \"{{name}}\";",
  ]

  default_ttl = 180
  max_ttl     = 300

  depends_on = [
    aws_rds_cluster.this,
    aws_rds_cluster_instance.this,
  ]
}

resource "vault_database_secret_backend_role" "read" {
  name    = "read"
  backend = vault_database_secrets_mount.postgres.path
  db_name = vault_database_secrets_mount.postgres.postgresql[0].name

  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}' INHERIT;",
    "GRANT CONNECT ON DATABASE postgres TO \"{{name}}\";",
    "REVOKE ALL ON SCHEMA public FROM \"{{name}}\";",
    "GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";",
    "GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO \"{{name}}\";",
    "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO \"{{name}}\";",
    "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO \"{{name}}\";",
    "REVOKE CREATE ON SCHEMA public FROM \"{{name}}\";",
  ]

  default_ttl = 180
  max_ttl     = 300

  depends_on = [
    aws_rds_cluster.this,
    aws_rds_cluster_instance.this,
  ]
}

resource "vault_policy" "aurora_database" {
  name   = "aurora-database"
  policy = file("aurora-database-policy.hcl")

  depends_on = [
    aws_rds_cluster.this,
    aws_rds_cluster_instance.this,
  ]
}

resource "vault_token" "boundary" {
  display_name = "boundary-database-token"
  policies = [
    "boundary-controller", # manage token
    "aurora-database",     # work with the postgres secrets engine
  ]
  no_default_policy = true
  no_parent         = true
  renewable         = true
  ttl               = "24h"
  period            = "1h"

  depends_on = [
    aws_rds_cluster.this,
    aws_rds_cluster_instance.this,
  ]
}
