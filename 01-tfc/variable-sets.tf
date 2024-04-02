# AWS --------------------------------------------------------------------------
resource "tfe_variable_set" "aws" {
  name        = "HUG-AWS-ADMIN"
  description = "AWS administrator access for IAM user"
}

resource "tfe_variable" "aws_region" {
  key             = "AWS_REGION"
  value           = var.aws_region
  variable_set_id = tfe_variable_set.aws.id
  category        = "env"
  description     = "AWS region name"
}

resource "tfe_variable" "aws_access_key_id" {
  key             = "AWS_ACCESS_KEY_ID"
  value           = aws_iam_access_key.hug.id
  variable_set_id = tfe_variable_set.aws.id
  category        = "env"
  description     = "AWS access key ID for IAM user"
  sensitive       = true
}

resource "tfe_variable" "aws_secret_access_key" {
  key             = "AWS_SECRET_ACCESS_KEY"
  value           = aws_iam_access_key.hug.secret
  variable_set_id = tfe_variable_set.aws.id
  category        = "env"
  description     = "AWS secret access key for IAM user"
  sensitive       = true
}

# Azure ------------------------------------------------------------------------
resource "tfe_variable_set" "azure" {
  name        = "HUG-AZURE-CONTRIBUTOR"
  description = "Azure contributor access"
}

resource "tfe_variable" "arm_client_id" {
  key             = "ARM_CLIENT_ID"
  value           = azuread_application.tfe.client_id
  variable_set_id = tfe_variable_set.azure.id
  category        = "env"
  description     = "Azure client ID"
}

resource "tfe_variable" "arm_client_secret" {
  key             = "ARM_CLIENT_SECRET"
  value           = azuread_application_password.tfe.value
  variable_set_id = tfe_variable_set.azure.id
  category        = "env"
  description     = "Azure client secret"
  sensitive       = true
}

resource "tfe_variable" "arm_subscription_id" {
  key             = "ARM_SUBSCRIPTION_ID"
  value           = data.azurerm_client_config.current.subscription_id
  variable_set_id = tfe_variable_set.azure.id
  category        = "env"
  description     = "Azure subscription ID"
}

data "azuread_client_config" "current" {}

resource "tfe_variable" "arm_tenant_id" {
  key             = "ARM_TENANT_ID"
  value           = data.azuread_client_config.current.tenant_id
  variable_set_id = tfe_variable_set.azure.id
  category        = "env"
  description     = "Azure tenant ID"
}

# TFE --------------------------------------------------------------------------
resource "tfe_variable_set" "tfe" {
  name        = "HUG-TFE-ADMIN"
  description = "Terraform Cloud team token"
}

resource "tfe_variable" "tfe_token" {
  key             = "TFE_TOKEN"
  value           = var.tfe_user_token
  variable_set_id = tfe_variable_set.tfe.id
  category        = "env"
  description     = "Terraform Cloud token"
  sensitive       = true
}

resource "tfe_variable" "tfe_organization" {
  key             = "TFE_ORGANIZATION"
  value           = var.tfe_organization_name
  variable_set_id = tfe_variable_set.tfe.id
  category        = "env"
  description     = "Terraform Cloud organization name"
}

# HCP --------------------------------------------------------------------------
resource "tfe_variable_set" "hcp" {
  name        = "HUG-HCP-CONTRIBUTOR"
  description = "HashiCorp Cloud Platform contributor credentials"
}

resource "tfe_variable" "hcp_client_id" {
  key             = "HCP_CLIENT_ID"
  value           = hcp_service_principal_key.hug.client_id
  variable_set_id = tfe_variable_set.hcp.id
  category        = "env"
  description     = "HashiCorp Cloud Platform client ID"
}

resource "tfe_variable" "hcp_client_secret" {
  key             = "HCP_CLIENT_SECRET"
  value           = hcp_service_principal_key.hug.client_secret
  variable_set_id = tfe_variable_set.hcp.id
  category        = "env"
  description     = "HashiCorp Cloud Platform client secret"
  sensitive       = true
}
