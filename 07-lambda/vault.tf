resource "vault_aws_secret_backend" "this" {
  path       = "aws"
  access_key = data.tfe_outputs.boundary.values.iam_user_vault.aws_access_key_id
  secret_key = data.tfe_outputs.boundary.values.iam_user_vault.aws_secret_access_key
  region     = var.aws_region
}

resource "vault_aws_secret_backend_role" "this" {
  name            = "invoke"
  credential_type = "assumed_role"
  backend         = vault_aws_secret_backend.this.path
  role_arns = [
    aws_iam_role.lambda.arn
  ]

  default_sts_ttl = 900
}

resource "vault_policy" "aurora_database" {
  name   = "aws"
  policy = file("aws.hcl")
}

resource "vault_token" "boundary" {
  display_name      = "boundary-database-token"
  policies          = ["boundary-controller", "aws"]
  no_default_policy = true
  no_parent         = true
  renewable         = true
  ttl               = "24h"
  period            = "1h"
}
