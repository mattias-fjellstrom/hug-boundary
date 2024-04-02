data "azuread_application_published_app_ids" "well_known" {}

resource "azuread_service_principal" "msgraph" {
  client_id    = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
  use_existing = true
}

resource "azuread_application" "tfe" {
  display_name = "Terraform Cloud - Azure Contributor"

  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph

    resource_access {
      id   = azuread_service_principal.msgraph.oauth2_permission_scope_ids["User.Read"]
      type = "Scope"
    }

    resource_access {
      id   = azuread_service_principal.msgraph.app_role_ids["User.ReadWrite.All"]
      type = "Role"
    }

    resource_access {
      id   = azuread_service_principal.msgraph.app_role_ids["Application.ReadWrite.All"]
      type = "Role"
    }

    resource_access {
      id   = azuread_service_principal.msgraph.app_role_ids["Group.ReadWrite.All"]
      type = "Role"
    }

    resource_access {
      id   = azuread_service_principal.msgraph.app_role_ids["GroupMember.ReadWrite.All"]
      type = "Role"
    }

    resource_access {
      id   = azuread_service_principal.msgraph.app_role_ids["DelegatedPermissionGrant.ReadWrite.All"]
      type = "Role"
    }
  }

  group_membership_claims = ["All"]
}

resource "azuread_service_principal" "tfe" {
  client_id = azuread_application.tfe.client_id
}

resource "azuread_application_password" "tfe" {
  application_id = azuread_application.tfe.id
  display_name   = "TFE"
}

resource "azuread_app_role_assignment" "user_readwrite_all" {
  app_role_id         = azuread_service_principal.msgraph.app_role_ids["User.ReadWrite.All"]
  principal_object_id = azuread_service_principal.tfe.object_id
  resource_object_id  = azuread_service_principal.msgraph.object_id
}

resource "azuread_app_role_assignment" "application_readwrite_all" {
  app_role_id         = azuread_service_principal.msgraph.app_role_ids["Application.ReadWrite.All"]
  principal_object_id = azuread_service_principal.tfe.object_id
  resource_object_id  = azuread_service_principal.msgraph.object_id
}
resource "azuread_app_role_assignment" "group_readwrite_all" {
  app_role_id         = azuread_service_principal.msgraph.app_role_ids["Group.ReadWrite.All"]
  principal_object_id = azuread_service_principal.tfe.object_id
  resource_object_id  = azuread_service_principal.msgraph.object_id
}

resource "azuread_app_role_assignment" "group_member_readwrite_all" {
  app_role_id         = azuread_service_principal.msgraph.app_role_ids["GroupMember.ReadWrite.All"]
  principal_object_id = azuread_service_principal.tfe.object_id
  resource_object_id  = azuread_service_principal.msgraph.object_id
}

resource "azuread_app_role_assignment" "delegated_permission_grant_readwrite_all" {
  app_role_id         = azuread_service_principal.msgraph.app_role_ids["DelegatedPermissionGrant.ReadWrite.All"]
  principal_object_id = azuread_service_principal.tfe.object_id
  resource_object_id  = azuread_service_principal.msgraph.object_id
}

resource "azuread_service_principal_delegated_permission_grant" "tfe" {
  service_principal_object_id          = azuread_service_principal.tfe.object_id
  resource_service_principal_object_id = azuread_service_principal.msgraph.object_id
  claim_values = [
    "User.ReadWrite.All",
    "Application.ReadWrite.All",
    "Group.ReadWrite.All",
    "GroupMember.ReadWrite.All",
    "DelegatedPermissionGrant.ReadWrite.All",
    "User.Read",
  ]
}

data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "contributor" {
  principal_id         = azuread_service_principal.tfe.object_id
  role_definition_name = "Contributor"
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
}
