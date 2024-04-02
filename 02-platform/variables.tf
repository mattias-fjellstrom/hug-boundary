variable "aws_instance_type" {
  default     = "t3.small"
  description = "EC2 instance type (TFC Agents)"
  type        = string
}

variable "aws_region" {
  default     = "eu-west-1"
  description = "AWS region"
  type        = string
}

variable "aws_vpc_cidr_block" {
  default     = "10.0.0.0/16"
  description = "AWS VPC CIDR block"
  type        = string
}

variable "entra_id_domain" {
  description = "Custom domain name for Entra ID"
  type        = string
}

variable "hcp_boundary_admin_password" {
  description = "Initial admin password for Boundary"
  sensitive   = true
  type        = string

  validation {
    condition     = length(var.hcp_boundary_admin_password) >= 12
    error_message = "Use at least 12 characters in the password"
  }
}

variable "hcp_vault_cloud_provider" {
  default     = "aws"
  description = "Cloud provider for hosting Vault cluster"
  type        = string

  validation {
    condition     = contains(["aws"], var.hcp_vault_cloud_provider)
    error_message = "This configuration is currently only compatible with AWS"
  }
}

variable "hcp_vault_tier" {
  default     = "dev"
  description = "HCP Vault service tier"
  type        = string

  validation {
    condition = contains([
      "dev",
      "starter_small",
      "standard_small",
      "plus_small"
    ], var.hcp_vault_tier)
    error_message = "Invalid HCP Vault service tier"
  }
}

variable "hcp_virtual_network_cidr" {
  description = "CIDR block for vault virtual network in HCP"
  type        = string
  default     = "192.168.0.0/16"
}

variable "peering_id" {
  type        = string
  description = "ID of the HCP/AWS peering connection"
  default     = "awshcp"
}
