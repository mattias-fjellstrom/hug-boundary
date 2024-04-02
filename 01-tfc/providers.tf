terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.43.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "2.47.0"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.97.1"
    }

    hcp = {
      source  = "hashicorp/hcp"
      version = "0.84.1"
    }

    tfe = {
      source  = "hashicorp/tfe"
      version = "0.53.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "azurerm" {
  features {}
}

provider "hcp" {}

provider "tfe" {
  organization = var.tfe_organization_name
  token        = var.tfe_user_token
}
