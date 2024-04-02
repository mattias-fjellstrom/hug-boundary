data "boundary_scope" "organization" {
  scope_id = "global"
  name     = "HashiCorp User Group"
}

data "boundary_scope" "aws" {
  scope_id = data.boundary_scope.organization.id
  name     = "AWS Resources"
}

resource "boundary_host_catalog_static" "lambda" {
  name        = "Lambda Catalog"
  description = "Lambda hosts"
  scope_id    = data.boundary_scope.aws.id
}

resource "boundary_host_static" "lambda" {
  name        = "aws-lambda"
  description = "Lambda host"

  address         = substr(aws_lambda_function_url.this.function_url, 8, length(aws_lambda_function_url.this.function_url) - 9)
  host_catalog_id = boundary_host_catalog_static.lambda.id
}

resource "boundary_host_set_static" "lambda" {
  name            = "aws-lambda-static-host-set"
  description     = "Host set for static AWS Lambda"
  host_catalog_id = boundary_host_catalog_static.lambda.id
  host_ids = [
    boundary_host_static.lambda.id,
  ]
}

resource "boundary_target" "lambda" {
  name        = "aws-lambda"
  description = "AWS Lambda function"
  scope_id    = data.boundary_scope.aws.id

  brokered_credential_source_ids = [
    boundary_credential_library_vault.invoke.id
  ]
  host_source_ids = [
    boundary_host_set_static.lambda.id,
  ]
  egress_worker_filter  = "\"public\" in \"/tags/subnet\""
  ingress_worker_filter = "\"public\" in \"/tags/subnet\""

  default_port             = 443
  session_connection_limit = -1
  type                     = "tcp"
}

resource "boundary_credential_store_vault" "aws" {
  name        = "boudary-vault-credential-store-aws"
  description = "Vault Credential Store for dynamic AWS credentials"
  address     = data.tfe_outputs.platform.values.vault_private_endpoint_url
  namespace   = "admin"
  scope_id    = data.boundary_scope.aws.id
  token       = vault_token.boundary.client_token

  // make sure only workers with access to Vault are used for this credential store
  worker_filter = "\"true\" in \"/tags/vault\""
}

resource "boundary_credential_library_vault" "invoke" {
  credential_store_id = boundary_credential_store_vault.aws.id
  name                = "Invoke"
  path                = "aws/sts/${vault_aws_secret_backend_role.this.name}"
  http_method         = "POST"
}

resource "boundary_role" "lambda_user" {
  name        = "lambda-user"
  description = "User for Lambda resources"
  scope_id    = data.boundary_scope.aws.id
  grant_strings = [
    "ids=${boundary_target.lambda.id};actions=read,authorize-session",
  ]
  principal_ids = [
    data.tfe_outputs.boundary.values.boundary_managed_groups.sre,
    data.tfe_outputs.boundary.values.boundary_managed_groups.dba,
    data.tfe_outputs.boundary.values.boundary_managed_groups.k8s,
  ]
}
