# ON-CALL --------------------------------------------------------------------------------------------------------------
resource "boundary_role" "oncall" {
  name        = "on-call"
  description = "Role for on-call engineers"
  grant_strings = [
    "ids=*;type=*;actions=read,list",
    "ids=*;type=target;actions=authorize-session",
  ]
  grant_scope_ids = [
    data.tfe_outputs.boundary.values.boundary_project_scope_id,
  ]
  scope_id = "global"
}

# LAMBDA ADMIN ---------------------------------------------------------------------------------------------------------
data "boundary_auth_method" "password" {
  name = "password"
}

resource "boundary_user" "lambda" {
  name        = "aws-lambda-admin"
  description = "User for AWS Lambda for on-call administration"
  scope_id    = "global"
  account_ids = [
    boundary_account_password.lambda.id
  ]
}

resource "boundary_account_password" "lambda" {
  name           = "aws-lambda-admin"
  description    = "Account for AWS Lambda for on-call administration"
  auth_method_id = data.boundary_auth_method.password.id
  login_name     = "aws-lambda"
  password       = data.tfe_outputs.platform.values.boundary_cluster.password
}

resource "boundary_role" "lambda" {
  name        = "aws-lambda-admin"
  description = "Role for AWS Lambda to administer the on-call role assignment"
  grant_strings = [
    "ids=${boundary_role.oncall.id};type=role;actions=read,list,add-principals,remove-principals",
  ]
  principal_ids = [
    boundary_user.lambda.id,
  ]
  scope_id = "global"
}
