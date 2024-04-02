terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.42.0"
    }

    boundary = {
      source  = "hashicorp/boundary"
      version = "1.1.14"
    }

    hcp = {
      source  = "hashicorp/hcp"
      version = "0.83.0"
    }

    tfe = {
      source  = "hashicorp/tfe"
      version = "0.53.0"
    }

    vault = {
      source  = "hashicorp/vault"
      version = "4.2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "boundary" {
  addr                   = data.tfe_outputs.platform.values.boundary_cluster.cluster_url
  auth_method_login_name = data.tfe_outputs.platform.values.boundary_cluster.username
  auth_method_password   = data.tfe_outputs.platform.values.boundary_cluster.password
}

provider "vault" {
  address = data.tfe_outputs.platform.values.vault_public_endpoint_url
  token   = data.tfe_outputs.platform.values.vault_admin_token
}

provider "tfe" {}
