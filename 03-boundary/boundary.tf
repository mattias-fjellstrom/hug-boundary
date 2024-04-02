# BOUNDARY SCOPES ------------------------------------------------------------------------------------------------------
resource "boundary_scope" "global" {
  global_scope = true
  scope_id     = "global"
  name         = "global"
}

resource "boundary_scope" "hug_organization" {
  scope_id                 = boundary_scope.global.id
  name                     = "HashiCorp User Group"
  description              = "User group organization for demo resources"
  auto_create_admin_role   = true
  auto_create_default_role = true
}

resource "boundary_scope" "aws" {
  scope_id                 = boundary_scope.hug_organization.id
  name                     = "AWS Resources"
  description              = "Project for all demo AWS resources"
  auto_create_admin_role   = true
  auto_create_default_role = true
}

# BOUNDARY AUTH METHODS ------------------------------------------------------------------------------------------------
resource "boundary_auth_method_oidc" "provider" {
  name                 = "Entra ID"
  description          = "OIDC auth method for Entra ID"
  scope_id             = boundary_scope.aws.scope_id
  issuer               = "https://sts.windows.net/${data.tfe_outputs.platform.values.oidc_configuration.tenant_id}/"
  client_id            = data.tfe_outputs.platform.values.oidc_configuration.client_id
  client_secret        = data.tfe_outputs.platform.values.oidc_configuration.client_secret
  signing_algorithms   = ["RS256"]
  api_url_prefix       = data.tfe_outputs.platform.values.boundary_cluster.cluster_url
  is_primary_for_scope = true
  state                = "active-public"
  claims_scopes        = ["groups"]
}

# BOUNDARY MANAGED GROUPS ----------------------------------------------------------------------------------------------
resource "boundary_managed_group" "dba" {
  auth_method_id = boundary_auth_method_oidc.provider.id
  description    = "Group for database administrators"
  name           = "dba-group"
  filter         = "\"${data.tfe_outputs.platform.values.dba_group.id}\" in \"/token/groups\""
}

resource "boundary_managed_group" "k8s" {
  auth_method_id = boundary_auth_method_oidc.provider.id
  description    = "Group for Kubernetes administrators"
  name           = "k8s-group"
  filter         = "\"${data.tfe_outputs.platform.values.k8s_group.id}\" in \"/token/groups\""
}

resource "boundary_managed_group" "sre" {
  auth_method_id = boundary_auth_method_oidc.provider.id
  description    = "Group for site reliability engineers"
  name           = "sre-group"
  filter         = "\"${data.tfe_outputs.platform.values.sre_group.id}\" in \"/token/groups\""
}

resource "boundary_managed_group" "oncall" {
  auth_method_id = boundary_auth_method_oidc.provider.id
  description    = "Group for on-call engineers"
  name           = "on-call-group"
  filter         = "\"${data.tfe_outputs.platform.values.oncall_group.id}\" in \"/token/groups\""
}

# BOUNDARY ROLES -------------------------------------------------------------------------------------------------------
resource "boundary_role" "reader" {
  name        = "reader"
  description = "Basic reader role for all groups"
  scope_id    = boundary_scope.aws.id
  grant_strings = [
    "ids=*;type=*;actions=list,no-op",
    "ids=*;type=session;actions=read:self,cancel:self",
    "ids=*;type=auth-token;actions=list,read:self,delete:self",
  ]
  principal_ids = [
    boundary_managed_group.dba.id,
    boundary_managed_group.k8s.id,
    boundary_managed_group.sre.id,
  ]
}
