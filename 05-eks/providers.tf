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

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.29.0"
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

provider "boundary" {
  addr                   = data.tfe_outputs.platform.values.boundary_cluster.cluster_url
  auth_method_login_name = data.tfe_outputs.platform.values.boundary_cluster.username
  auth_method_password   = data.tfe_outputs.platform.values.boundary_cluster.password
}

provider "kubernetes" {
  host                   = aws_eks_cluster.this.endpoint
  token                  = data.aws_eks_cluster_auth.this.token
  cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
}

provider "tfe" {}
