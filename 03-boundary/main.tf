data "tfe_outputs" "platform" {
  workspace = "02-platform"
}

data "hcp_packer_artifact" "boundary" {
  bucket_name  = "boundary"
  channel_name = "latest"
  platform     = "aws"
  region       = "eu-west-1"
}
