variable "aws_region" {
  type        = string
  description = "AWS region name for all resources"
}

variable "hcp_boundary_admin_password" {
  type        = string
  description = "HCP Boundary admin password (also used for Azure user credentials)"
}

variable "github_repository_identifier" {
  type        = string
  description = "Name of repo where all source code is located <github handle>/<repository name>"
}

variable "tfe_github_app_installation_number" {
  type        = number
  description = "GitHub App installation number (use API to obtain)"
}

variable "tfe_organization_name" {
  type        = string
  description = "Terraform Cloud organization name"
}

variable "tfe_user_token" {
  type        = string
  description = "TFC user token for TFC management"
}
