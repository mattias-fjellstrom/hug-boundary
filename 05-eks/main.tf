data "tfe_outputs" "platform" {
  workspace = "02-platform"
}

data "tfe_outputs" "boundary" {
  workspace = "03-boundary"
}

data "aws_caller_identity" "current" {}
