terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.42.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "2.47.0"
    }

    hcp = {
      source  = "hashicorp/hcp"
      version = "0.83.0"
    }

    tfe = {
      source  = "hashicorp/tfe"
      version = "0.53.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "hcp" {}

provider "tfe" {}
