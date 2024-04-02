data "boundary_scope" "organization" {
  scope_id = "global"
  name     = "HashiCorp User Group"
}

data "boundary_scope" "aws" {
  scope_id = data.boundary_scope.organization.id
  name     = "AWS Resources"
}

resource "boundary_credential_store_vault" "ec2" {
  name        = "boudary-vault-credential-store-ec2"
  scope_id    = data.boundary_scope.aws.id
  description = "Vault Credential Store for EC2 SSH certificates"

  // vault settings
  address   = data.tfe_outputs.platform.values.vault_private_endpoint_url
  token     = vault_token.boundary.client_token
  namespace = "admin"

  // make sure only workers with access to Vault are used for this credential store
  worker_filter = "\"true\" in \"/tags/vault\""
}

resource "boundary_credential_library_vault_ssh_certificate" "ec2" {
  name                = "ssh-certs"
  description         = "Vault SSH certificate credential library"
  credential_store_id = boundary_credential_store_vault.ec2.id
  path                = "ssh-client-signer/sign/boundary-client"

  username = "ubuntu"
  key_type = "ecdsa"
  key_bits = 521
  extensions = {
    permit-pty = ""
  }
}

resource "boundary_role" "ec2_admin" {
  name        = "ec2-admin"
  description = "Administrator for EC2 resources"
  scope_id    = data.boundary_scope.aws.id
  grant_strings = [
    "ids=*;type=*;actions=list,no-op",
    "ids=${boundary_target.dynamic_dev.id};actions=read,authorize-session",
    "ids=${boundary_target.dynamic_prod.id};actions=read,authorize-session",
    "ids=${boundary_target.ec2_isolated.id};actions=read,authorize-session",
    "ids=${boundary_target.ec2_private.id};actions=read,authorize-session",
  ]
  principal_ids = [
    data.tfe_outputs.boundary.values.boundary_managed_groups.sre,
  ]
}
