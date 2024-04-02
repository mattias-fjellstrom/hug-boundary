data "boundary_scope" "organization" {
  scope_id = "global"
  name     = "HashiCorp User Group"
}

data "boundary_scope" "aws" {
  scope_id = data.boundary_scope.organization.id
  name     = "AWS Resources"
}

# HOST AND TARGET ------------------------------------------------------------------------------------------------------
resource "boundary_host_catalog_static" "aurora" {
  name        = "Aurora Cluster Catalog"
  description = "Aurora hosts"
  scope_id    = data.boundary_scope.aws.id
}

resource "boundary_host_static" "postgres" {
  name            = "aws-aurora-postgres"
  description     = "Aurora postgres host"
  address         = aws_rds_cluster.this.endpoint
  host_catalog_id = boundary_host_catalog_static.aurora.id
}

resource "boundary_host_set_static" "aurora" {
  name            = "aws-aurora-static-host-set"
  description     = "Host set for static AWS Aurora cluster"
  host_catalog_id = boundary_host_catalog_static.aurora.id
  host_ids = [
    boundary_host_static.postgres.id,
  ]
}

resource "boundary_target" "readwrite" {
  name        = "aws-aurora-read/write"
  description = "AWS Aurora RDS statically created hosts"
  scope_id    = data.boundary_scope.aws.id

  brokered_credential_source_ids = [
    boundary_credential_library_vault.readwrite.id
  ]
  egress_worker_filter = "\"private\" in \"/tags/subnet\""
  host_source_ids = [
    boundary_host_set_static.aurora.id,
  ]
  ingress_worker_filter = "\"public\" in \"/tags/subnet\""

  default_port             = 5432
  session_connection_limit = -1
  type                     = "tcp"
}

resource "boundary_target" "read" {
  name        = "aws-aurora-read"
  description = "AWS Aurora RDS statically created hosts"
  scope_id    = data.boundary_scope.aws.id

  brokered_credential_source_ids = [
    boundary_credential_library_vault.read.id
  ]
  egress_worker_filter = "\"private\" in \"/tags/subnet\""
  host_source_ids = [
    boundary_host_set_static.aurora.id,
  ]
  ingress_worker_filter = "\"public\" in \"/tags/subnet\""

  default_port             = 5432
  session_connection_limit = -1
  type                     = "tcp"
}

# CREDENTIALS ----------------------------------------------------------------------------------------------------------
resource "boundary_credential_store_vault" "db" {
  name        = "boudary-vault-credential-store-db"
  description = "Vault Credential Store for dynamic postgres credentials"
  address     = data.tfe_outputs.platform.values.vault_private_endpoint_url
  namespace   = "admin"
  scope_id    = data.boundary_scope.aws.id
  token       = vault_token.boundary.client_token

  // make sure only workers with access to Vault are used for this credential store
  worker_filter = "\"true\" in \"/tags/vault\""
}

resource "boundary_credential_library_vault" "readwrite" {
  credential_store_id = boundary_credential_store_vault.db.id
  name                = "Read/Write"
  path                = "database/creds/readwrite"
}

resource "boundary_credential_library_vault" "read" {
  credential_store_id = boundary_credential_store_vault.db.id
  name                = "Read"
  path                = "database/creds/read"
}

# ROLES ----------------------------------------------------------------------------------------------------------------
resource "boundary_role" "dba_admin" {
  name        = "dba-admin"
  description = "Administrator for RDS resources"
  scope_id    = data.boundary_scope.aws.id
  grant_strings = [
    "ids=${boundary_target.read.id};actions=read,authorize-session",
    "ids=${boundary_target.readwrite.id};actions=read,authorize-session",
  ]
  principal_ids = [
    data.tfe_outputs.boundary.values.boundary_managed_groups.dba,
  ]
}
